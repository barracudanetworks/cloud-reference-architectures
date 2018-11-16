<?php include('config.inc.php'); ?>
<html>
<head>
<title>Barracuda Demo Web App</title>
<style>
body { text-align: center; }
table {
  margin: auto;
}

</style>
</head>

<body>
<h1><?php echo DEPLOYMENTCOLOR; ?></h1>
<table>
<?php
$rows = 7;
$cols = 12;
$colspan = 6;
$rowspan = 3;
$colstart = 3;
$rowstart = 2;

for ( $rowcnt = 0 ; $rowcnt < $rows ; $rowcnt++ ) {
        echo '<tr>';
        for ( $colcnt = 0 ; $colcnt < $cols ; $colcnt++ ) {
                if ( $rowcnt==$rowstart && $colcnt==$colstart ) {
                        echo "<td colspan=$colspan rowspan=$rowspan >";
                        $mysqli = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

			// Oh no! A connect_errno exists so the connection attempt failed!
			if ($mysqli->connect_errno) {
				// The connection failed. What do you want to do? 
				// You could contact yourself (email?), log the error, show a nice page, etc.
				// You do not want to reveal sensitive information
			
				// Let's try this:
				echo "Unable to connect to the database";
			
				// Something you should not do on a public site, but this example will show you
				// anyways, is print out MySQL error related information -- you might log this
				echo "Error: Failed to make a MySQL connection, here is why: \n";
				echo "Errno: " . $mysqli->connect_errno . "\n";
				echo "Error: " . $mysqli->connect_error . "\n";
			}
			?>
<form>
<input name="needle"><input type="submit" value="Search color"><br>
</form>
			<?php
			if (!empty( $_GET[ 'needle' ])) {
				$needle = $_GET[ 'needle' ];	
				$sql = "SELECT * FROM colors WHERE name LIKE '$needle'";
				if (!$result = $mysqli->query($sql)) {
					// Oh no! The query failed. 
					echo "Sorry, the website is experiencing problems.";
				} else {
					if (!$result = $mysqli->query($sql)) {
						echo "Sorry, the website is experiencing problems.";
					} else {
						if ($result && $result->num_rows) {  
							// just one match - display it
							$hexid = $result->fetch_assoc()['hexid'];  
							$color = $result->fetch_assoc()['name'];  
							echo '<div style="background-color: #' . $hexid;
							echo '; width: 80px; height: 80px; float: right; border: 1px solid black;">&nbsp;</div>';
							echo '<div style="font-size:4em;float: left;">' . $color;
							echo '</div>';
						}
					}
				}
			}
			echo "</td>";
		}
		if ( $colcnt >= $colstart && $colcnt < ( $colstart + $colspan ) && $rowcnt >= $rowstart && $rowcnt < ( $rowstart+$rowspan )) {
			$colcnt += $colspan;
		}
		echo '<td>';
		echo '<img src="blank.png?' .md5( rand() ). '">';
		echo '</td>';
	}
	echo '</tr>';
}
?>
</table>
</body>
</html>