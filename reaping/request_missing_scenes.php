<?php
    
    // https://espa.cr.usgs.gov/ordering/status/
    
    
    // get a list of all the raw files we have
    include('../config.php');
    
    $in_path_rows = '"' . implode('","', $path_rows) . '"';
    
    // get a list of the scenes we don't have a download record for
    $sql = "SELECT ls.landsat_product_id as prod_id FROM LANDSAT_8_C1 as ls 
         LEFT JOIN downloads as d ON ls.landsat_product_id = d.product_id 
         WHERE
    	 concat(`ls`.`path` , '_', `ls`.`row`)  in ($in_path_rows)
    	 AND d.`status` is NULL
    	 AND ls.dayOrNight = 'DAY'
    	 AND CLOUD_COVER_LAND < 90
         ORDER BY CLOUD_COVER_LAND * 1 ASC";
    	 
    $result = $mysqli->query($sql);
    
    $new_prods = array();
    while ($row = $result->fetch_assoc()) {
        $new_prods[] = $row['prod_id'];
    }
    $result->free();
    
    echo count($new_prods) . " new scenes found\n";
    
    $limit = 10;
    foreach($new_prods as $prod_id){
        
        echo $prod_id . "\n";
                                  
        $data_string = get_order_string($prod_id);
    
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $usga_api_url . '/order');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $data_string);    
        curl_setopt($ch, CURLOPT_HTTPHEADER, array(                                                                          
            'Content-Type: application/json',                                                                                
            'Content-Length: ' . strlen($data_string))                                                                       
        );
        curl_setopt($ch, CURLOPT_USERPWD, "$usgs_user:$usgs_password");
        curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
        $output = curl_exec($ch);
        $info = curl_getinfo($ch);
        curl_close($ch);
        
        print_r($output);
        //print_r($info);
        
        $from_usgs = json_decode($output);
        
        print_r($from_usgs);
        
        if(isset($from_usgs->status)){
            $status = $from_usgs->status;
            if($status == 'ordered'){
                $order_id = $from_usgs->orderid;
            }else{
                $order_id = null;
            }
        }else{
            $status = $info['http_code'];
            $order_id = null;
        }
        
        // update the database with the order status
        $stmt = $mysqli->prepare("INSERT INTO downloads (`product_id`, `status`, `order_id`, `message`) VALUES (?,?,?,?)");
        $stmt->bind_param("ssss", $prod_id, $status, $order_id, $output);
        $stmt->execute();
                
        if($limit-- < 1) break;
    }
    
    function get_order_string($prod_id){
        
        $usgs_order_ob = array(
              'olitirs8_collection' => array(
                  'inputs' => array($prod_id),
                  'products'  => array("sr", "sr_ndvi", "pixel_qa")
            ),
            'format' => "gtiff", 
            'plot_statistics' => FALSE, 
            'projection' => array('lonlat' => NULL),
            'note' => "From PHP Script usgs_place_order"
          );
          
         return json_encode($usgs_order_ob);
        
    }
    
?>