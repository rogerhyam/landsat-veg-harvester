<?php
    
    // get a list of all the raw files we have
   include('../config.php');
   
   // get a list of open orders
   $sql = "SELECT order_id FROM downloads WHERE (status = 'ordered' OR status = 'submitted') AND order_id IS NOT NULL;";
   $result = $mysqli->query($sql);
   $rows = $result->fetch_all(MYSQLI_ASSOC);

   foreach($rows as $row){
       
       $order_id = $row['order_id'];
       
       // call for the status
       $ch = curl_init();
       curl_setopt($ch, CURLOPT_URL, $usga_api_url . '/item-status/' . $order_id);
       curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
       curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
       curl_setopt($ch, CURLOPT_USERPWD, "$usgs_user:$usgs_password");
       $output = curl_exec($ch);
       $info = curl_getinfo($ch);
       curl_close($ch);
       
       $from_usgs = json_decode($output);
       //print_r($from_usgs);
       $item = $from_usgs->$order_id[0];
       
       echo "\n$item->name\n";
       
       // download it if it is complete
       if($item->status == 'complete'){
           
           echo "\tDownloading $item->name ...          "; 
           //$worked = file_put_contents($data_directory . '/raw/tars/'. $item->name . '.tar.gz', fopen($item->product_dload_url, 'r'));
           //$worked = true;
           
           $ch = curl_init();
           curl_setopt($ch, CURLOPT_URL, $item->product_dload_url);
           $fp = fopen($data_directory . '/raw/tars/'. $item->name . '.tar.gz', 'w+');
           curl_setopt($ch, CURLOPT_FILE, $fp);
           curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 30); // if we don't hear back in 30 seconds then fail
           curl_setopt($ch, CURLOPT_PROGRESSFUNCTION, 'curl_progress'); // needed for progress to work
           curl_setopt($ch, CURLOPT_TIMEOUT, 10 * 60); // if we can't get it in 10 minutes we give up - 
           curl_setopt($ch, CURLOPT_NOPROGRESS, false);
           $worked = curl_exec ($ch);
           curl_close ($ch);
           fclose($fp);
           
           // we leave the table if it failed so we can try again.
           if($worked){
               echo " - done\n"; 
               update_downloads_table($item->name, 'downloaded', $worked . ' bytes');
           }else{
               echo " - failed\n"; 
           }
               
       }else{
           echo "\t$item->status\n"; 
           update_downloads_table($item->name, $item->status, $item->note);
       }
       
   }
   
   function curl_progress($resource,$download_size, $downloaded, $upload_size, $uploaded)
   {
       echo "\033[12D"; // delete 12 characters
       echo str_pad(number_format($downloaded), 12, ' ', STR_PAD_LEFT);
       return(0);
   }
   
   
   function update_downloads_table($prod_id, $status, $message){
       global $mysqli;
       $stmt = $mysqli->prepare("UPDATE downloads SET `status` = ?, `message` = ? WHERE product_id =  ?");
       $stmt->bind_param("sss", $status, $message, $prod_id);
       $stmt->execute();
   }
    
?>