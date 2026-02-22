let () =
  Lwt_main.run
    (Alcotest_lwt.run "testcontainers-mariadb"
       [ ("mariadb", Test_mariadb.suite) ])
