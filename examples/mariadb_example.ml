(** MariaDB example: Running MariaDB for integration tests *)

open Lwt.Syntax
open Testcontainers_mariadb

let () =
  Lwt_main.run
    begin
      Printf.printf "Starting MariaDB container...\n%!";

      Mariadb_container.with_mariadb
        ~config:(fun c ->
          c
          |> Mariadb_container.with_database "myapp_test"
          |> Mariadb_container.with_username "testuser"
          |> Mariadb_container.with_password "testpass"
          |> Mariadb_container.with_root_password "rootpass")
        (fun container conn_str ->
          Printf.printf "MariaDB is ready!\n%!";
          Printf.printf "Connection string: %s\n%!" conn_str;

          let* host = Mariadb_container.host container in
          let* port = Mariadb_container.port container in

          Printf.printf "Host: %s\n%!" host;
          Printf.printf "Port: %d\n%!" port;

          Printf.printf "Running database tests...\n%!";
          Lwt_unix.sleep 1.0)
    end;
  Printf.printf "MariaDB container cleaned up.\n"
