# MariaDB

The MariaDB module provides a pre-configured container for integration testing with MariaDB databases.

## Quick Start

```ocaml
open Lwt.Syntax
open Testcontainers_mariadb

let test_mariadb () =
  Mariadb_container.with_mariadb (fun container connection_string ->
    Printf.printf "MariaDB running at: %s\n" connection_string;
    Lwt.return_unit
  )
```

## Installation

```bash
opam install testcontainers-mariadb
```

In your `dune` file:

```scheme
(libraries testcontainers-mariadb)
```

## Configuration

### Basic Configuration

```ocaml
Mariadb_container.with_mariadb
  ~config:(fun c -> c
    |> Mariadb_container.with_database "myapp"
    |> Mariadb_container.with_username "appuser"
    |> Mariadb_container.with_password "secret123"
    |> Mariadb_container.with_root_password "rootsecret")
  (fun container conn_str ->
    (* conn_str: mariadb://appuser:secret123@127.0.0.1:33061/myapp *)
    ...
  )
```

### Configuration Options

| Function | Default | Description |
|----------|---------|-------------|
| `with_image` | `mariadb:11` | Docker image |
| `with_database` | `test` | Database name |
| `with_username` | `test` | Username |
| `with_password` | `test` | Password |
| `with_root_password` | `root` | Root password |

### Custom Image

```ocaml
Mariadb_container.with_mariadb
  ~config:(fun c -> c
    |> Mariadb_container.with_image "mariadb:10.11"
    |> Mariadb_container.with_database "legacy_db")
  (fun container conn_str -> ...)
```

## Connection Details

### Connection String

```
mariadb://username:password@host:port/database
```

### JDBC URL

```ocaml
let* jdbc_url = Mariadb_container.jdbc_url config container in
(* jdbc:mariadb://127.0.0.1:33061/test *)
```

### Individual Components

```ocaml
Mariadb_container.with_mariadb (fun container conn_str ->
  let* host = Mariadb_container.host container in
  let* port = Mariadb_container.port container in
  let database = Mariadb_container.database config in
  let username = Mariadb_container.username config in
  ...
)
```

## Manual Lifecycle

```ocaml
let run_tests () =
  let config =
    Mariadb_container.create ()
    |> Mariadb_container.with_database "testdb"
    |> Mariadb_container.with_username "admin"
    |> Mariadb_container.with_password "secret"
    |> Mariadb_container.with_root_password "rootpass"
  in

  let* container = Mariadb_container.start config in
  let* conn_str = Mariadb_container.connection_string config container in

  (* Run tests... *)

  let* () = Testcontainers.Container.terminate container in
  Lwt.return_unit
```

## Wait Strategy

MariaDB logs "ready for connections" twice during startup:
1. First for the temporary server during initialization
2. Second when the final server is ready on port 3306

The module waits for the second occurrence:

```ocaml
Wait_strategy.for_log ~occurrence:2 "ready for connections"
```
