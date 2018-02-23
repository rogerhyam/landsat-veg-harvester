<?php

    include('../../secure_config.php');

    $data_directory = '/Volumes/RepoBack2TB/landsat-data';
    $usga_api_url = 'https://espa.cr.usgs.gov/api/v0';
    
    $path_rows = array(
        '204_21', '205_21', '206_21', '204_20', '205_20', '206_20'
    );
    
    $mysqli = new mysqli('127.0.0.1', $db_user, $db_password, 'greenery');
    if ($mysqli->connect_errno) {
        echo "Errno: " . $mysqli->connect_errno . "\n";
        echo "Error: " . $mysqli->connect_error . "\n";   
    }

?>