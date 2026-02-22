(** Tests for MariaDB module *)

open Lwt.Syntax

let skip_integration_tests () =
  match Sys.getenv_opt "SKIP_INTEGRATION_TESTS" with
  | Some "1" | Some "true" -> true
  | _ -> false

let string_starts_with ~prefix s =
  let plen = String.length prefix in
  String.length s >= plen && String.sub s 0 plen = prefix

let string_contains ~needle s =
  let nlen = String.length needle in
  let slen = String.length s in
  let rec loop i =
    if i + nlen > slen then false
    else if String.sub s i nlen = needle then true
    else loop (i + 1)
  in
  if nlen = 0 then true else loop 0

let test_config _switch () =
  let config =
    Testcontainers_mariadb.Mariadb_container.create ()
    |> Testcontainers_mariadb.Mariadb_container.with_database "mydb"
    |> Testcontainers_mariadb.Mariadb_container.with_username "admin"
    |> Testcontainers_mariadb.Mariadb_container.with_password "secret"
  in
  Alcotest.(check string)
    "database" "mydb"
    (Testcontainers_mariadb.Mariadb_container.database config);
  Alcotest.(check string)
    "username" "admin"
    (Testcontainers_mariadb.Mariadb_container.username config);
  Alcotest.(check string)
    "password" "secret"
    (Testcontainers_mariadb.Mariadb_container.password config);
  Lwt.return_unit

let test_container _switch () =
  if skip_integration_tests () then Lwt.return_unit
  else begin
    Testcontainers_mariadb.Mariadb_container.with_mariadb
      ~config:(fun c ->
        c
        |> Testcontainers_mariadb.Mariadb_container.with_database "testdb"
        |> Testcontainers_mariadb.Mariadb_container.with_username "testuser"
        |> Testcontainers_mariadb.Mariadb_container.with_password "testpass"
        |> Testcontainers_mariadb.Mariadb_container.with_root_password
             "rootpass")
      (fun container conn_str ->
        Alcotest.(check bool)
          "connection string not empty" true
          (String.length conn_str > 0);
        Alcotest.(check bool)
          "connection string contains mariadb://" true
          (string_starts_with ~prefix:"mariadb://" conn_str);
        let* host = Testcontainers_mariadb.Mariadb_container.host container in
        Alcotest.(check string) "host is localhost" "127.0.0.1" host;
        let* exit_code, output =
          Testcontainers.Container.exec container
            [
              "sh";
              "-c";
              "mariadb -u testuser -ptestpass testdb -e 'SELECT 1;' || \
               mysql -u testuser -ptestpass testdb -e 'SELECT 1;'";
            ]
        in
        Alcotest.(check int) "query command succeeds" 0 exit_code;
        Alcotest.(check bool)
          "query output contains 1" true
          (string_contains ~needle:"1" output);
        Lwt.return_unit)
  end

let suite =
  [
    Alcotest_lwt.test_case "config" `Quick test_config;
    Alcotest_lwt.test_case "container" `Slow test_container;
  ]
