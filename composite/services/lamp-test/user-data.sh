#!/bin/bash
yum update -y
amazon-linux-extras install php8.0 mariadb10.5
yum -y install httpd
systemctl start httpd
systemctl enable httpd

usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

mkdir /var/www/inc

cat > /var/www/inc/dbinfo.inc <<EOF
<?php

define('DB_SERVER', '${db_endpoint}');
define('DB_USERNAME', 'admin');
define('DB_PASSWORD', '${db_password}');
define('DB_DATABASE', 'lamptest');

?>
EOF

cat > /var/www/html/SamplePage.php <<EOF
<?php include "../inc/dbinfo.inc"; ?>
<html>
<body>
<h1>Sample page</h1>
<?php

  /* Connect to MySQL and select the database. */
  \$connection = mysqli_connect(DB_SERVER, DB_USERNAME, DB_PASSWORD);

  if (mysqli_connect_errno()) echo "Failed to connect to MySQL: " . mysqli_connect_error();

  \$database = mysqli_select_db(\$connection, DB_DATABASE);

  /* Ensure that the EMPLOYEES table exists. */
  VerifyEmployeesTable(\$connection, DB_DATABASE);

  /* If input fields are populated, add a row to the EMPLOYEES table. */
  \$employee_name = htmlentities(\$_POST['NAME']);
  \$employee_address = htmlentities(\$_POST['ADDRESS']);

  if (strlen(\$employee_name) || strlen(\$employee_address)) {
    AddEmployee(\$connection, \$employee_name, \$employee_address);
  }
?>

<!-- Input form -->
<form action="<?PHP echo \$_SERVER['SCRIPT_NAME'] ?>" method="POST">
  <table border="0">
    <tr>
      <td>NAME</td>
      <td>ADDRESS</td>
    </tr>
    <tr>
      <td>
        <input type="text" name="NAME" maxlength="45" size="30" />
      </td>
      <td>
        <input type="text" name="ADDRESS" maxlength="90" size="60" />
      </td>
      <td>
        <input type="submit" value="Add Data" />
      </td>
    </tr>
  </table>
</form>

<!-- Display table data. -->
<table border="1" cellpadding="2" cellspacing="2">
  <tr>
    <td>ID</td>
    <td>NAME</td>
    <td>ADDRESS</td>
  </tr>

<?php

\$result = mysqli_query(\$connection, "SELECT * FROM EMPLOYEES");

while(\$query_data = mysqli_fetch_row(\$result)) {
  echo "<tr>";
  echo "<td>",\$query_data[0], "</td>",
       "<td>",\$query_data[1], "</td>",
       "<td>",\$query_data[2], "</td>";
  echo "</tr>";
}
?>

</table>

<!-- Clean up. -->
<?php

  mysqli_free_result(\$result);
  mysqli_close(\$connection);

?>

</body>
</html>


<?php

/* Add an employee to the table. */
function AddEmployee(\$connection, \$name, \$address) {
   \$n = mysqli_real_escape_string(\$connection, \$name);
   \$a = mysqli_real_escape_string(\$connection, \$address);

   \$query = "INSERT INTO EMPLOYEES (NAME, ADDRESS) VALUES ('\$n', '\$a');";

   if(!mysqli_query(\$connection, \$query)) echo("<p>Error adding employee data.</p>");
}

/* Check whether the table exists and, if not, create it. */
function VerifyEmployeesTable(\$connection, \$dbName) {
  if(!TableExists("EMPLOYEES", \$connection, \$dbName))
  {
     \$query = "CREATE TABLE EMPLOYEES (
         ID int(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
         NAME VARCHAR(45),
         ADDRESS VARCHAR(90)
       )";

     if(!mysqli_query(\$connection, \$query)) echo("<p>Error creating table.</p>");
  }
}

/* Check for the existence of a table. */
function TableExists(\$tableName, \$connection, \$dbName) {
  \$t = mysqli_real_escape_string(\$connection, \$tableName);
  \$d = mysqli_real_escape_string(\$connection, \$dbName);

  \$checktable = mysqli_query(\$connection,
      "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_NAME = '\$t' AND TABLE_SCHEMA = '\$d'");

  if(mysqli_num_rows(\$checktable) > 0) return true;

  return false;
}
?>                                     
EOF

cat > /var/www/html/index.html <<EOF
<h1>${server_text}</h1>
<p>DB address: ${db_address}</p>
<p>DB port: ${db_port}</p>
EOF