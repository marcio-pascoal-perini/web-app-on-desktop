<?php

//ini_set('display_errors', 1);
error_reporting(E_ALL ^ E_NOTICE ^ E_WARNING ^ E_STRICT);

date_default_timezone_set('America/Sao_Paulo');

function openWeather($query)
{
    $apiID = 'YOUR API ID';
    $url = "https://api.openweathermap.org/data/2.5/weather?q=$query&units=metric&APPID=$apiID";
    $handle = curl_init();
    curl_setopt($handle, CURLOPT_HEADER, 0);
    curl_setopt($handle, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($handle, CURLOPT_URL, $url);
    curl_setopt($handle, CURLOPT_FOLLOWLOCATION, 1);
    curl_setopt($handle, CURLOPT_VERBOSE, 0);
    curl_setopt($handle, CURLOPT_SSL_VERIFYPEER, FALSE);
    $response = curl_exec($handle);
    if ($response == FALSE) {
        $result = curl_error($handle);
    } else {
        $result = json_decode($response);
    }
    curl_close($handle);
    return $result;
}

function getCities()
{
    $data = '[]';
    try {
        $db = new SQLite3('db/openweather.db');
        $db->enableExceptions(TRUE);
        $db->exec('CREATE TABLE IF NOT EXISTS Cities (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);');
        $result = $db->query('SELECT name FROM Cities ORDER BY name;');
        $data = '[';
        while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
            $data .= "'" . $row['name'] . "',";
        }
        $data .= ']';
        $data = str_replace(',]', ']', $data);
        $db->close();
    } catch (Exception $error) {
    }
    return $data;
}

function setCity($name)
{
    try {
        $db = new SQLite3('db/openweather.db');
        $db->enableExceptions(TRUE);
        $db->exec('CREATE TABLE IF NOT EXISTS Cities (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);');
        $count = $db->querySingle("SELECT COUNT(*) as count FROM Cities WHERE name = '$name'");
        if ($count == 0) {
            $db->exec("INSERT INTO Cities (name) VALUES ('$name');");
        }
        $db->close();
    } catch (Exception $error) {
    }
}
