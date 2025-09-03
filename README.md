# newconstruct

`newconstruct` is a simple command-line tool for Go that automatically generates a `New...` constructor function for a given type definition in a source file. It is designed to be integrated with editors like Neovim to speed up development.

## Features

* Generates constructors for both `struct` types and simple type definitions (e.g., `type Name string`).
* For structs, the constructor accepts parameters for all fields.
* Parameter names are automatically generated as lowercase versions of field names.
* Fast and simple, designed to be called by an editor plugin.

## Installation

To install the `newconstruct` executable, ensure you have Go installed and your `GOPATH` is set up correctly, then run:

```bash
go install [github.com/ddromanidis/newconstruct@latest](https://github.com/ddromanidis/newconstruct@latest)```

## Example

```go
package models

import "time"

// Relative path is models/user.go
// Line of User struct is number 7
type User struct {
    ID        int
    FirstName string
    IsActive  bool
    CreatedAt time.Time
}
```

```bash
newconstruct --file=models/user.go --line=7```

This will generate an output to stdout:

```go
func NewUser(id int, firstname string, isactive bool, createdat time.Time) User {
	return User{
		ID:        id,
		FirstName: firstname,
		IsActive:  isactive,
		CreatedAt: createdat,
	}
}
```
