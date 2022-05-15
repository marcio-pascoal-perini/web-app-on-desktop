package main

import (
	"database/sql"
	"flag"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"path/filepath"

	_ "github.com/mattn/go-sqlite3"
)

var (
	host  *string
	port  *int
	views = template.Must(template.ParseGlob(patternPath()))
)

type Contact struct {
	ID          int
	Name        string
	Address     string
	Email       string
	Phone       string
	Coordinates string
}

func basePath() string {
	dir, err := filepath.Abs(filepath.Dir(os.Args[0]))
	if err != nil {
		log.Fatal(err.Error())
	}
	return dir
}

func dbConnection() (db *sql.DB) {
	s := `
	CREATE TABLE IF NOT EXISTS Contacts (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT,
		address TEXT,
		email TEXT,
		phone TEXT,
		coordinates TEXT
	);
	`
	db, err := sql.Open("sqlite3", dbPath())
	if err != nil {
		log.Fatal(err.Error())
	}
	statement, err := db.Prepare(s)
	if err != nil {
		log.Fatal(err.Error())
	}
	statement.Exec()
	return db
}

func dbPath() string {
	dir, err := filepath.Abs(filepath.Dir(os.Args[0]))
	if err != nil {
		log.Fatal(err.Error())
	}
	return filepath.Join(dir, "db", "CRUD.db")
}

func handleRequests(host *string, port *int) {
	fs := http.FileServer(http.Dir(filepath.Join(basePath(), "assets")))
	http.Handle("/assets/", http.StripPrefix("/assets/", fs))
	http.HandleFunc("/", Index)
	http.HandleFunc("/create", Create)
	http.HandleFunc("/delete", Delete)
	http.HandleFunc("/details", Details)
	http.HandleFunc("/edit", Edit)
	http.HandleFunc("/insert", Insert)
	http.HandleFunc("/update", Update)
	fmt.Printf("Listening on %s:%d\n", *host, *port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf("%s:%d", *host, *port), nil))
}

func main() {
	host = flag.String("host", "localhost", "Current host")
	port = flag.Int("port", 5200, "Port number")
	flag.Parse()
	handleRequests(host, port)
}

func patternPath() string {
	dir, err := filepath.Abs(filepath.Dir(os.Args[0]))
	if err != nil {
		log.Fatal(err.Error())
	}
	return filepath.Join(dir, "views/*.html")
}

func Create(w http.ResponseWriter, r *http.Request) {
	views.ExecuteTemplate(w, "Create", nil)
}

func Delete(w http.ResponseWriter, r *http.Request) {
	db := dbConnection()
	id := r.URL.Query().Get("id")
	result, err := db.Prepare("DELETE FROM Contacts WHERE id=?")
	if err != nil {
		log.Fatal(err.Error())
	}
	result.Exec(id)
	defer db.Close()
	http.Redirect(w, r, "/", http.StatusMovedPermanently)
}

func Details(w http.ResponseWriter, r *http.Request) {
	db := dbConnection()
	id := r.URL.Query().Get("id")
	result, err := db.Query("SELECT * FROM Contacts WHERE id=?", id)
	if err != nil {
		log.Fatal(err.Error())
	}
	contact := Contact{}
	for result.Next() {
		var id int
		var name, address, email, phone, coordinates string
		err = result.Scan(&id, &name, &address, &email, &phone, &coordinates)
		if err != nil {
			log.Fatal(err.Error())
		}
		contact.ID = id
		contact.Name = name
		contact.Address = address
		contact.Email = email
		contact.Phone = phone
		contact.Coordinates = coordinates
	}
	views.ExecuteTemplate(w, "Details", contact)
	defer db.Close()
}

func Edit(w http.ResponseWriter, r *http.Request) {
	db := dbConnection()
	id := r.URL.Query().Get("id")
	result, err := db.Query("SELECT * FROM Contacts WHERE id=?", id)
	if err != nil {
		log.Fatal(err.Error())
	}
	contact := Contact{}
	for result.Next() {
		var id int
		var name, address, email, phone, coordinates string
		err = result.Scan(&id, &name, &address, &email, &phone, &coordinates)
		if err != nil {
			log.Fatal(err.Error())
		}
		contact.ID = id
		contact.Name = name
		contact.Address = address
		contact.Email = email
		contact.Phone = phone
		contact.Coordinates = coordinates
	}
	views.ExecuteTemplate(w, "Edit", contact)
	defer db.Close()
}

func Index(w http.ResponseWriter, r *http.Request) {
	db := dbConnection()
	result, err := db.Query("SELECT * FROM Contacts ORDER BY id DESC")
	if err != nil {
		log.Fatal(err.Error())
	}
	contact := Contact{}
	contacts := []Contact{}
	for result.Next() {
		var id int
		var name, address, email, phone, coordinates string
		err = result.Scan(&id, &name, &address, &email, &phone, &coordinates)
		if err != nil {
			log.Fatal(err.Error())
		}
		contact.ID = id
		contact.Name = name
		contact.Address = address
		contact.Email = email
		contact.Phone = phone
		contact.Coordinates = coordinates
		contacts = append(contacts, contact)
	}
	views.ExecuteTemplate(w, "Index", contacts)
	defer db.Close()
}

func Insert(w http.ResponseWriter, r *http.Request) {
	db := dbConnection()
	if r.Method == "POST" {
		name := r.FormValue("name")
		address := r.FormValue("address")
		email := r.FormValue("email")
		phone := r.FormValue("phone")
		coordinates := r.FormValue("coordinates")
		result, err := db.Prepare("INSERT INTO Contacts(name, address, email, phone, coordinates) VALUES(?,?,?,?,?)")
		if err != nil {
			log.Fatal(err.Error())
		}
		result.Exec(name, address, email, phone, coordinates)
	}
	defer db.Close()
	http.Redirect(w, r, "/", http.StatusMovedPermanently)
}

func Update(w http.ResponseWriter, r *http.Request) {
	db := dbConnection()
	if r.Method == "POST" {
		name := r.FormValue("name")
		address := r.FormValue("address")
		email := r.FormValue("email")
		phone := r.FormValue("phone")
		coordinates := r.FormValue("coordinates")
		id := r.FormValue("uid")
		result, err := db.Prepare("UPDATE Contacts SET name=?, address=?, email=?, phone=?, coordinates=? WHERE id=?")
		if err != nil {
			log.Fatal(err.Error())
		}
		result.Exec(name, address, email, phone, coordinates, id)
	}
	defer db.Close()
	http.Redirect(w, r, "/", http.StatusMovedPermanently)
}
