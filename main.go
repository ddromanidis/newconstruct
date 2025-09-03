package main

import (
	"bytes"
	"errors"
	"flag"
	"fmt"
	"go/ast"
	"go/parser"
	"go/printer"
	"go/token"
	"log"
	"os"
	"strconv"
	"strings"
)

var errNotFound = errors.New("no type definition found at the target line")

type Name string

type Kek struct {
	a, b int
}

func NewKek(a int, b int) Kek {
	return Kek{
		a: a,
		b: b,
	}
}

func generateConstructor(source []byte, targetLine int) (string, error) {
	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, "source.go", source, parser.ParseComments)
	if err != nil {
		return "", fmt.Errorf("could not parse source file: %w", err)
	}

	var (
		targetStruct   *ast.StructType
		typeName       string
		underlyingType ast.Expr
		isStruct       bool
		found          bool
	)

	ast.Inspect(node, func(n ast.Node) bool {
		if n == nil || found {
			return false
		}

		typeSpec, ok := n.(*ast.TypeSpec)
		if !ok {
			return true
		}

		startLine := fset.Position(typeSpec.Pos()).Line
		endLine := fset.Position(typeSpec.End()).Line

		if !(targetLine >= startLine && targetLine <= endLine) {
			return true
		}

		found = true
		typeName = typeSpec.Name.Name

		if structType, ok := typeSpec.Type.(*ast.StructType); ok {
			isStruct = true
			targetStruct = structType
		} else {
			isStruct = false
			underlyingType = typeSpec.Type
		}

		return false
	})

	if !found {
		return "", errNotFound
	}

	var sb strings.Builder

	if isStruct {
		var params []string
		var assignments []string

		for _, field := range targetStruct.Fields.List {
			if len(field.Names) == 0 {
				continue
			}
			typeStr := typeExprToString(fset, field.Type)

			for _, fieldName := range field.Names {
				paramName := strings.ToLower(fieldName.Name)
				params = append(params, fmt.Sprintf("%s %s", paramName, typeStr))
				assignments = append(
					assignments,
					fmt.Sprintf("\t\t%s: %s,", fieldName.Name, paramName),
				)
			}
		}

		paramList := strings.Join(params, ", ")

		sb.WriteString(fmt.Sprintf("func New%s(%s) %s {\n", typeName, paramList, typeName))
		sb.WriteString(fmt.Sprintf("\treturn %s{\n", typeName))

		sb.WriteString(strings.Join(assignments, "\n"))
		if len(assignments) > 0 {
			sb.WriteString("\n")
		}

		sb.WriteString("\t}\n")
		sb.WriteString("}\n")
	} else {
		underlyingTypeStr := typeExprToString(fset, underlyingType)
		sb.WriteString(fmt.Sprintf("func New%s(value %s) %s {\n", typeName, underlyingTypeStr, typeName))
		sb.WriteString(fmt.Sprintf("\treturn %s(value)\n", typeName))
		sb.WriteString("}\n")
	}

	return sb.String(), nil
}

func typeExprToString(fset *token.FileSet, expr ast.Expr) string {
	var buf bytes.Buffer
	if err := printer.Fprint(&buf, fset, expr); err != nil {
		return "interface{}"
	}
	return buf.String()
}

func main() {
	filePath := flag.String("file", "", "Path to the Go source file")
	lineStr := flag.String("line", "0", "Line number of the type definition")
	flag.Parse()

	if *filePath == "" {
		log.Fatal("Error: --file argument is required.")
	}
	if *lineStr == "0" {
		log.Fatal("Error: --line argument is required.")
	}

	line, err := strconv.Atoi(*lineStr)
	if err != nil {
		log.Fatalf("Error: invalid line number provided: %v", err)
	}

	content, err := os.ReadFile(*filePath)
	if err != nil {
		log.Fatalf("Error: failed to read file '%s': %v", *filePath, err)
	}

	constructor, err := generateConstructor(content, line)
	if err != nil {
		log.Fatalf("Error: %v", err)
	}

	fmt.Print(constructor)
}
