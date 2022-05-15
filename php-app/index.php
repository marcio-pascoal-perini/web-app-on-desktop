<?php
require_once 'definitionsAndFunctions.php';

$error = NULL;
$data = NULL;

if (isset($_POST['query'])) {
    $query = trim($_POST['query']);
} else {
    $query = NULL;
}

if ($query != NULL) {
    $data = openWeather($query);
    if (gettype($data) == 'object') {
        $code = intval($data->cod);
        if (200 <= $code && $code <= 299) {
            $error = NULL;
            setCity($data->name . ', ' . $data->sys->country);
        } else {
            $error = $data->message;
            $data = NULL;
        }
    } else {
        $error = $data;
        $data = NULL;
    }
}
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/x-icon" href="/assets/images/favicon.png">
    <link href="/assets/bootstrap/css/bootstrap.min.css" rel="stylesheet">
    <link href="/assets/styles/autocomplete.css" rel="stylesheet">
    <link href="/assets/leaflet/leaflet.css" rel="stylesheet">
    <script src="/assets/bootstrap/js/bootstrap.bundle.min.js"></script>
    <script src="/assets/scripts/autocomplete.js"></script>
    <script src="/assets/leaflet/leaflet.js"></script>
    <title>OpenWeather</title>
    <style>
        #map {
            position: relative;
            height: 100%;
            width: 100%;
        }
    </style>
    <script type="text/javascript">
        function dateTimeLocal(dt, tz) {
            const unixTimestamp = dt + tz;
            const milliseconds = eval(unixTimestamp * 1000);
            const dateObject = new Date(milliseconds);
            return dateObject.toGMTString();
        }

        window.onload = function() {
            document.getElementById('query').focus();
        };

        if (window.history.replaceState) {
            window.history.replaceState(null, null, window.location.href);
        }
    </script>
</head>

<body>
    <div class="container">
        <div class="row row-cols-1">
            <div class="col text-center">
                <h1>OpenWeather</h1>
            </div>
            <div class="col text-center">&nbsp;</div>
            <div class="col">
                <div class="row row-cols-2">
                    <div class="col">
                        <form id="form" name="form" class="d-grid gap-2 d-md-flex left-content-md-end" method="post">
                            <div class="autocomplete" onclick="document.getElementById('search').click();">
                                <input id="query" name="query" class="form-control" type="text" placeholder="Example: Paris, FR">
                            </div>
                            <button id="search" name="search" class="btn btn-primary" type="submit">Search</button>
                        </form>
                        <div class="col">&nbsp;</div>
                        <div class="table-responsive">
                            <table class="table table-bordered table-hover">
                                <tbody>
                                    <tr>
                                        <th scope="row">Temperature</th>
                                        <td>
                                            <?php
                                            if ($data != NULL) {
                                                $icon = $data->weather[0]->icon;
                                                $temp = round($data->main->temp, 0);
                                                echo "<img src='https://openweathermap.org/img/w/$icon.png'>";
                                                echo $temp . '°C';
                                            }
                                            ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th scope="row">City</th>
                                        <td>
                                            <?php
                                            if ($data != NULL) {
                                                echo $data->name . ', ' . $data->sys->country;
                                            }
                                            ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th scope="row">Coordinates</th>
                                        <td>
                                            <?php
                                            if ($data != NULL) {
                                                echo $data->coord->lat . ', ' . $data->coord->lon;
                                            }
                                            ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th scope="row">Date / Time</th>
                                        <td>
                                            <?php
                                            if ($data != NULL) {
                                                $dt = $data->dt;
                                                $tz = $data->timezone;
                                                echo "<script>document.write(dateTimeLocal($dt, $tz));</script>";
                                            }
                                            ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th scope="row">Weather</th>
                                        <td>
                                            <?php
                                            if ($data != NULL) {
                                                echo $data->weather[0]->main . ', ' . $data->weather[0]->description;
                                            }
                                            ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th scope="row">Minimum temperature</th>
                                        <td>
                                            <?php
                                            if ($data != NULL) {
                                                echo round($data->main->temp_min, 0) . '°C';
                                            }
                                            ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th scope="row">Maximum temperature</th>
                                        <td>
                                            <?php
                                            if ($data != NULL) {
                                                echo round($data->main->temp_max, 0) . '°C';
                                            }
                                            ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th scope="row">Feels like</th>
                                        <td>
                                            <?php
                                            if ($data != NULL) {
                                                echo round($data->main->feels_like, 0) . '°C';
                                            }
                                            ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th scope="row">Humidity</th>
                                        <td>
                                            <?php
                                            if ($data != NULL) {
                                                echo $data->main->humidity . '%';
                                            }
                                            ?>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="col">
                        <div id="map"></div>
                    </div>
                </div>
            </div>
        </div>
        <div id="errorDialog" name="errorDialog" class="modal">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">Error</h4>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <h5 id="message" name="message"></h5>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-primary" data-bs-dismiss="modal">Ok</button>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script type="text/javascript">
        function showErrorDialog(message) {
            const modal = new bootstrap.Modal(document.getElementById('errorDialog'));
            document.getElementById('message').innerHTML = message;
            modal.show();
        }

        const input = document.getElementById('query');

        input.addEventListener('keyup', (event) => {
            if (event.keyCode == 13) {
                event.preventDefault();
                document.getElementById('search').click();
            }
        });

        <?php
        echo 'const cities = ' . getCities() . ';';
        ?>
        autocomplete(input, cities);

        <?php
        if ($data == NULL) {
            echo "const map = L.map('map').setView([23.113062, -30.106429], 2);";
            echo "L.marker([23.113062, -30.106429]).addTo(map);";
        } else {
            $lat = $data->coord->lat;
            $lon = $data->coord->lon;
            echo "const map = L.map('map').setView([$lat, $lon], 12);";
            echo "L.marker([$lat, $lon]).addTo(map);";
        }
        ?>
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a>'
        }).addTo(map);
    </script>
    <?php
    if ($error != NULL) {
        echo "<script>showErrorDialog('$error');</script>";
    }
    ?>
</body>

</html>