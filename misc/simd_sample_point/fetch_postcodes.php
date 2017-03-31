<?php

    // this wi
    
/*    http://statistics.gov.scot/area_collection?in_collection=http%3A%2F%2Fstatistics.gov.scot%2Fdef%2Fgeography%2Fcollection%2Fpostcodes&within_area=http%3A%2F%2Fstatistics.gov.scot%2Fid%2Fstatistical-geography%2FS01008684
*/

$data_zones = file('remote.txt');

$headers = array(
    "DataZone",
    "PostCode",
    "Latitude",
    "Longitude",
    "Eastings",
    "Northings",
    "AvDistance",
    "wkt",
    "Picked"
);

$fp = fopen('out_remote.csv', 'w');

fputcsv($fp, $headers);

$counter = 0;
foreach($data_zones as $dz){
    
    $data_zone = trim($dz);
    
    echo $counter++;
    $rows = get_postcodes($data_zone);

    // write the rows to a file
    foreach ($rows as $row) {
        fputcsv($fp, $row);
    }
    
    echo "\t$data_zone\n";
    
}

fclose($fp);

echo "All Done!";


function get_postcodes($data_zone){
    
    /*
        Some vocabs used
    */
    $ords_postcode = "http://data.ordnancesurvey.co.uk/ontology/postcode/PostcodeUnit";
    $ords_easting = "http://data.ordnancesurvey.co.uk/ontology/spatialrelations/easting";
    $ords_northing = "http://data.ordnancesurvey.co.uk/ontology/spatialrelations/northing";
    $wgs_lat = "http://www.w3.org/2003/01/geo/wgs84_pos#lat";
    $wgs_lon = "http://www.w3.org/2003/01/geo/wgs84_pos#long";
    $rdf_label = "http://www.w3.org/2000/01/rdf-schema#label";
    $rdf_val = "@value";
    $rdf_id = "@id";

    $data_url = "http://statistics.gov.scot/area_collection.jsonld?in_collection=http%3A%2F%2Fstatistics.gov.scot%2Fdef%2Fgeography%2Fcollection%2Fpostcodes&within_area=http%3A%2F%2Fstatistics.gov.scot%2Fid%2Fstatistical-geography%2F";
    
    $data_url .= $data_zone;

    $ch = curl_init($data_url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    curl_close($ch);

    $response = json_decode($response);
    
    $rows = array();
    $counter = 0;
    foreach($response as $postcode){
        
        if(!isset($postcode->$wgs_lat[0]->$rdf_val)) continue;
        
        $row = array();
        $row[] = $data_zone;        
        $row[] = $postcode->$rdf_label[0]->$rdf_val;
        $row[] = $postcode->$wgs_lat[0]->$rdf_val;
        $row[] = $postcode->$wgs_lon[0]->$rdf_val;
        $row[] = $postcode->$ords_easting[0]->$rdf_val;
        $row[] = $postcode->$ords_northing[0]->$rdf_val;

        $rows[] = $row;
        
    }
    
    // tack on the average distance to neighbour
    $rows_width_d = array();
    $min_average_distance = 100000;
    foreach($rows as $pc){
        $wkt_lines = array();
        $dist_total = 0;
        foreach($rows as $neighbour){

            // don't do self
            if($pc[1] == $neighbour[1]) continue;
            
            $n = abs($pc[5] - $neighbour[5]); // northings
            $e = abs($pc[4] - $neighbour[4]); // eastings
            $dist_total += sqrt(pow($n,2) + pow($e,2)); // pythagorus
            
            // add a line to for each neighbour
            $wkt_lines[] = '(' . $pc[4] . ' ' . $pc[5] . ',' . $neighbour[4] . ' ' . $neighbour[5] . ')';
            
        }
        
        // write the distance in
        $dist_average = round($dist_total/count($rows));
        $pc[] = $dist_average;
        
        // add in the wkt of the calculation
        //$pc[] = 'GEOMETRYCOLLECTION(POINT('. $pc[4] . ' ' . $pc[5] . '), MULTILINESTRING('. implode(',', $wkt_lines) . '))';
        
        $pc[] = 'POINT('. $pc[4] . ' ' . $pc[5] . ')';
        
        // add it to the list
        $rows_with_d[] = $pc;
        
        // keep track of the min distance
        if($dist_average < $min_average_distance) $min_average_distance = $dist_average;
    }
    
    
    // flag prefered 
    $rows_with_d_flagged = array();
    $picked_one = false;
    foreach($rows_with_d as $pc){
        if(!$picked_one && $pc[6] == $min_average_distance){
            $pc[] = 1;
            $picked_one = true;
        }else{
            $pc[] = 0;
        }
        
        $rows_with_d_flagged[] = $pc;
        // echo "\t" . implode("\t", $pc) . "\n";
    }

    return $rows_with_d_flagged;
}




?>
