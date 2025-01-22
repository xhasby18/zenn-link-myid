<?php
$servername = "localhost";
$database = "database1";
$username = "root";
$password = "123456";
 
// Membuat Koneksi
 
$conn = mysqli_connect($servername, $username, $password, $database);
 
// Cek Koneksi
 
if (!$conn) {
 
    die("Koneksi Gagal: " . mysqli_connect_error());
 
}
echo "Berhasil Terhubung dengan Database";
mysqli_close($conn);
?>