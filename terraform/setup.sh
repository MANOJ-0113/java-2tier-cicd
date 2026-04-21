#!/bin/bash

apt update -y
apt upgrade -y

# Install Required Packages
apt install -y openjdk-17-jdk maven nginx postgresql-client

# Create Project Directories
mkdir -p /home/manoj/employee-api/src/main/java/com/example/employeeapi/model
mkdir -p /home/manoj/employee-api/src/main/java/com/example/employeeapi/repository
mkdir -p /home/manoj/employee-api/src/main/java/com/example/employeeapi/controller
mkdir -p /home/manoj/employee-api/src/main/resources

cd /home/manoj/employee-api

# -----------------------------
# Create pom.xml
# -----------------------------
cat > pom.xml <<POM
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

<modelVersion>4.0.0</modelVersion>

<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.2.0</version>
</parent>

<groupId>com.example</groupId>
<artifactId>employee-api</artifactId>
<version>1.0.0</version>

<properties>
    <java.version>17</java.version>
</properties>

<dependencies>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>

    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <scope>runtime</scope>
    </dependency>

</dependencies>

<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>

</project>
POM

# -----------------------------
# Create application.properties
# -----------------------------
cat > src/main/resources/application.properties <<PROPS
spring.datasource.url=jdbc:postgresql://myapp-postgres-server.postgres.database.azure.com:5432/employeedb?sslmode=require
spring.datasource.username=manoj
spring.datasource.password=Chawakula%400113

spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect

server.port=8080
PROPS

# -----------------------------
# Create Main Application File
# -----------------------------
cat > src/main/java/com/example/employeeapi/EmployeeApiApplication.java <<MAIN
package com.example.employeeapi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class EmployeeApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(EmployeeApiApplication.class, args);
    }
}
MAIN

# -----------------------------
# Create Employee Entity
# -----------------------------
cat > src/main/java/com/example/employeeapi/model/Employee.java <<ENTITY
package com.example.employeeapi.model;

import jakarta.persistence.*;

@Entity
@Table(name = "employees")
public class Employee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String email;
    private String department;
    private Double salary;

    public Employee() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public Double getSalary() { return salary; }
    public void setSalary(Double salary) { this.salary = salary; }
}
ENTITY

# -----------------------------
# Create Repository
# -----------------------------
cat > src/main/java/com/example/employeeapi/repository/EmployeeRepository.java <<REPO
package com.example.employeeapi.repository;

import com.example.employeeapi.model.Employee;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EmployeeRepository extends JpaRepository<Employee, Long> {
}
REPO

# -----------------------------
# Create Controller
# -----------------------------
cat > src/main/java/com/example/employeeapi/controller/EmployeeController.java <<CTRL
package com.example.employeeapi.controller;

import com.example.employeeapi.model.Employee;
import com.example.employeeapi.repository.EmployeeRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/employees")
public class EmployeeController {

    private final EmployeeRepository repo;

    public EmployeeController(EmployeeRepository repo) {
        this.repo = repo;
    }

    @GetMapping
    public List<Employee> getAll() {
        return repo.findAll();
    }

    @GetMapping("/{id}")
    public Employee getOne(@PathVariable Long id) {
        return repo.findById(id).orElseThrow();
    }

    @PostMapping
    public Employee create(@RequestBody Employee employee) {
        return repo.save(employee);
    }

    @PutMapping("/{id}")
    public Employee update(@PathVariable Long id, @RequestBody Employee employee) {

        Employee old = repo.findById(id).orElseThrow();

        old.setName(employee.getName());
        old.setEmail(employee.getEmail());
        old.setDepartment(employee.getDepartment());
        old.setSalary(employee.getSalary());

        return repo.save(old);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        repo.deleteById(id);
    }
}
CTRL

# -----------------------------
# Build Project
# -----------------------------
mvn clean package -DskipTests

# -----------------------------
# Run Application
# -----------------------------
nohup java -jar target/employee-api-1.0.0.jar > app.log 2>&1 &

# -----------------------------
# Configure Nginx
# -----------------------------
cat > /etc/nginx/sites-available/default <<NGINX
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
NGINX

# Restart Services
systemctl restart nginx
systemctl enable nginx

# Ownership
chown -R manoj:manoj /home/manoj/employee-api