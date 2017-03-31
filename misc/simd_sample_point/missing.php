<?php

    // add in the ones that didn't have picks selected because some of their members were lacking lon/lats
    
    $rows = file('missing.csv');
    $fp = fopen('out_missed.csv', 'w');
    
    $current_dz = "";
    $postcodes = array();
    foreach($rows as $row){
        $pc = str_getcsv($row);
        
        // move to the next data zone
        if($current_dz != $pc[0]){
            if(count($postcodes)) process_dz($postcodes);
            $current_dz = $pc[0];
            $postcodes = array();
        }
        
        // add it to the list and keep going
        $postcodes[] = $pc;

    }
    // do the final one
    if(count($postcodes)) process_dz($postcodes);
    
    fclose($fp);
    
    echo "All Done\n";
    
    
    
    function process_dz($postcodes){
        
        global $fp;
        
        // work out the correct distances
        $new_postcodes = array();
        $min_average_distance = 10000;
        foreach($postcodes as $pc){
            $dist_total = 0;
            foreach($postcodes as $neighbour){

                // don't do self
                if($pc[1] == $neighbour[1]) continue;

                $n = abs($pc[5] - $neighbour[5]); // northings
                $e = abs($pc[4] - $neighbour[4]); // eastings
                $dist_total += sqrt(pow($n,2) + pow($e,2)); // pythagorus

            }
            
            $dist_average = round($dist_total/count($postcodes));
            $new_pc = $pc;
            $new_pc[6] = $dist_average;
            $new_postcodes[] = $new_pc;
            
            // keep track of the min distance
            if($dist_average < $min_average_distance) $min_average_distance = $dist_average;
            
        }
        
        // Choose the smallest

        foreach($new_postcodes as $pc){
            if($pc[6] == $min_average_distance){
                $pc[8] = 1;
                fputcsv($fp, $pc);
                print_r($pc);
            }
        }
        
        
    }


?>