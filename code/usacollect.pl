#!/usr/bin/perl

# DEV-DATE: 3/20/03
# PROD-DATE: 
# AUTH: Jon W. Raugutt
# PROG: usacollect.pl
# DESC: Application to display decorative hardware collections
# Uses edirect shared MYSQL database.

# REVISIONS:


# call in Perl Database Interface 
use DBI;
use Image::Info qw(image_info dim);
require qw(usalib.pl);

# call HTML form parsing subroutine
&parse();

# DECLARE GLOBAL VARIABLES
$img_url = 'http://www.usacabinethardware.com/img/';
$cgi_url = 'http://www.usacabinethardware.com/cgi-bin/';
$secure_cgi = 'https://secure.usacabinethardware.com/cgi-bin/';
$base_url = 'http://www.usacabinethardware.com/';
$secure_url = 'https://secure.usacabinethardware.com/';
#$home_dir = '/var/www/html/usa/';
$home_dir = '/vhosts/usacabinethardware.com/htdocs/';
$session_id = '';
$site_id = '4';
$location = $secure_cgi . 'usastore.pl';


# OPEN TWO CONNECTIONS TO MYSQL DB SERVER
$DB_edirect = DBI->connect('DBI:mysql:edirect:localhost:', 'edweb', 'gh0rAc', {
        RaiseError=>1,
        PrintError=>1
});
$DB2_edirect = DBI->connect('DBI:mysql:edirect:localhost:', 'edweb', 'gh0rAc', {
        RaiseError=>1,
        PrintError=>1
});

$form{bid} = 639 if (!exists($form{bid}));
$form{did} = 240 if (!exists($form{did}));

$ST_DB = $DB_edirect->prepare("SELECT DISTINCT c.brand_id, brand 
                        FROM collections c, brands b
            WHERE c.brand_id = b.brand_id
            and c.dept_id = $form{did}");
$ST_DB->execute();
$brands = $ST_DB->fetchall_arrayref();
$ST_DB->finish();

$brand = $DB_edirect->selectrow_array("SELECT brand FROM brands 
                                WHERE brand_id = $form{bid}");
                                
                                                 
if (!$form{st} || $form{st} == 1) {
        if (exists($form{p})) {
                $pageNo = $form{p};
        } else {
                $pageNo = 1;
        }
        my $numRecords = $DB_edirect->selectrow_array("SELECT count(*) FROM collections
                                                WHERE brand_id = $form{bid}");
        my $numRows = $numRecords / 4;
        my $numPages = $numRecords / 16;        
        
        if ($numPages =~ m/\d\.\d/) {
                $numPages = sprintf("%d", $numPages);
                $numPages += 1;
        }                               
        
        if (exists($form{dir})) {
                if ($form{dir} eq 'nxt') {
                        $start = $pageNo * 16;
                        $pageNo += 1;
                } elsif ($form{dir} eq 'pre') {
                        $start = ($pageNo - 1) * 16 - 16;
                        $pageNo -= 1;
                }
        } else {
                $start = 0;
        }
                                                
        $ST_DB = $DB_edirect->prepare("SELECT coll_id, coll_name FROM collections
                                                WHERE brand_id = $form{bid}
                                                and dept_id = $form{did}
                                                ORDER BY coll_name ASC
                                                LIMIT $start, 16");
        $ST_DB->execute();

        &page_header("$brand Product Collections - USACabinetHardware.com");
    
        print qq^<div id="subHeaderContainer">
                  <div class="subHeader">$brand - PAGE $pageNo of $numPages</div></div><div>^;
                
        if ($form{bid} == 700) {
            print qq^<br><div style="font-weight:bold;color:#D20000;font-size:11pt;text-align:center">
		TOP KNOBS REQUIRES A SIGNATURE FOR ALL DELIVERIES</div>^;
        }
                
        print qq^<br/><br/><br/><table border=0 width=100% cellpadding=0 cellspacing=10 bgcolor=#FFFFFF>
                                <tr><td valign=top style="text-align:center;margin-bottom:10px" colspan=5 bgcolor=#DD808C>
                                        <table style="background-color:#DD808C;border:2px solid #9B5A62;width:100%" cellspacing=0>
                                                <tr><form method=post action=usacollect.pl>
                                                <input type=hidden name=st value=1>
                                                <td align=center>
                                                <select style="font-size:13pt" name=bid onChange="this.form.submit()" class=frmField>
                                                <option value=$form{bid}>$brand</option>^;
                        
        foreach my $this_brand (@$brands) {
                my ($bid, $bname) = @$this_brand;
                print qq^<option value="$bid">$bname</option>^;
        }
    
    
    print qq^</select></td></form><form method=post action=usacollect.pl>
                                                <input type=hidden name=st value=2>
                                                <input type=hidden name=bid value=$form{bid}>
                                                <td align=center>
                                                <select style="font-size:13pt" name=cid onChange="this.form.submit()" class=frmField>
                                                <option>-- COLLECTION --</option>^;
        
        $ST2_DB = $DB2_edirect->prepare("SELECT coll_id, coll_name FROM collections
                                                WHERE brand_id = $form{bid}
                                                and dept_id = $form{did}
                                                ORDER BY coll_name ASC");
                                                                                        
        $ST2_DB->execute();
        
        while (my ($id, $name) = $ST2_DB->fetchrow_array()) {
                print qq^<option value="$id">$name</option>^;
        }
        
        print qq^</select></td></form>^;
                                                
        if ($pageNo != 1) {
                print qq^<td class=small align=center>
                            <button class=formButton onClick="window.location='${cgi_url}usacollect.pl?bid=$form{bid}&p=$pageNo&dir=pre'">&lt; previous page</button></td>^
        }
        
        if ($pageNo != $numPages) {
                print qq^<td class=small align=center>
                                                <button class=formButton onClick="window.location='${cgi_url}usacollect.pl?bid=$form{bid}&p=$pageNo&dir=nxt'">next page &gt;</button></td>
                                                </tr>^;
        }
        
        print qq^</table>
                      </td></tr><tr style="padding-top:20px">^;
                                        
        my $count = 1;
        while (my ($id, $name) = $ST_DB->fetchrow_array()) {
                if ($count >= 5) {
                        print "</tr><tr><td><br></td></tr><tr>";
                        $count =  1;
                }
                print qq^<td style="background-color:#FFF;text-align:center;padding-top:10px;padding-bottom:10px" class=small>
                        <a href="usacollect.pl?bid=$form{bid}&st=2&cid=$id">^;
                
                if (-e "${home_dir}img/coll/thmb/$form{bid}-$id\.jpg") {
                        print qq^<img src="${img_url}coll/thmb/$form{bid}-$id\.jpg" border=0>^;
                }
                
                print "<br>$name</a></td>";
                $count++;
        }
        
    print qq^<tr><td valign=top align=center colspan=5 bgcolor=#DD808C style="margin-top:10px">
                                        <table style="background-color:#DD808C;border:2px solid #9B5A62;width:100%">
                                                <tr><form method=post action=usacollect.pl>
                                                <input type=hidden name=st value=1>
                                                <td align=center>
                                                <select style="font-size:13pt" name=bid onChange="this.form.submit()" class=frmField>
                                                <option value=$form{bid}>$brand</option>^;
        foreach my $this_brand (@$brands) {
                my ($bid, $bname) = @$this_brand;
        print qq^<option value="$bid">$bname</option>^;
    }
    
    
    print qq^</select></td></form>
                                                <form method=post action=usacollect.pl>
                                                <input type=hidden name=st value=2>
                                                <input type=hidden name=bid value=$form{bid}>
                                                <td align=center>
                                                <select style="font-size:13pt" name=cid onChange="this.form.submit()" class=frmField>
                                                <option>-- COLLECTION --</option>^;
                                                
        $ST2_DB->execute();
        
        while (my ($id, $name) = $ST2_DB->fetchrow_array()) {
                print qq^<option value="$id">$name</option>^;
        }
        $ST2_DB->finish();
        print qq^
                                                </select></td></form>^;
        
        if ($pageNo != 1) {
                print qq^<td class=norm align=center>
                                                <button class=formButton onClick="window.location='${cgi_url}usacollect.pl?bid=$form{bid}&p=$pageNo&dir=pre'">&lt; previous page</button></td>^
        }
        
        if ($pageNo != $numPages) {
                print qq^<td class=norm align=center>
                                                <button class=formButton onClick="window.location='${cgi_url}usacollect.pl?bid=$form{bid}&p=$pageNo&dir=nxt'">next page &gt;</button></td>
                                                </tr>^;
        }
        
        print qq^</table>
                     </td></tr></table></div>^;
        
        $ST_DB->finish();

################### STEP 2 #################
} elsif ($form{st} == 2) {
        my ($product_query, $coll_query);
        
        $query = "SELECT SQL_CALC_FOUND_ROWS DISTINCT p.prod_id, model_num, group_id, detail_descp, 
                  size1, size2, finish, unit, price, disc_qty, 
                  stock, qty_oh, ship_time
                        FROM  products p, collection_items ci 
                        WHERE status != 0
                        and p.brand_id = $form{bid}
                        and ci.brand_id = $form{bid}
                        and ci.coll_id = $form{cid}
                        and ci.prod_id = p.prod_id";

        $query .= " and status != 0 
                    GROUP BY group_id, model_num";
        
        if (exists($form{sortBy}) && $form{sortBy} ne '') {
            my ($field, $order) = split(/-/, $form{sortBy});
            $query .= " ORDER BY $field $order";
        } else {
            $query .= " ORDER BY p.brand_id";
        }
        
        if (!$form{ind}) {
                $form{ind} = 20;
                $query .= ' LIMIT 20';
        } else {
                $query .= ' LIMIT ' . $form{ind} . ', 20';
                $form{ind} += 20;
        }

        $coll_query = "SELECT b.brand_id, brand, coll_id, coll_name  
                        FROM brands AS b
                        LEFT JOIN collections AS c USING(brand_id)
                        WHERE c.coll_id = $form{cid}
                        and c.brand_id = $form{bid}";
   
    &page_header();     
#   print qq^QUERY: $query  <br>COUNT_QUERY: $count_query <br>COLL_QUERY: $coll_query<br>
#         BRAND: $brand<br>^;
#   exit;     
        my $coll_image = $form{bid} . '-' . $form{cid} . '.jpg';   
        if (-e "${home_dir}img/coll/$coll_image") {                                      
                &display_page2("$query", "$coll_query");
        } else {
                &display_page("$query", "$coll_query");
        }
                
                
}


&page_footer();
&closeDBConnections();
exit();


################################################################################
######################### DISPLAY CATALOG PAGE SUBROUTINE ######################
sub display_page {
        my ($query, $count, $results, $first_item, $numRows);
        
        ($query, $coll_query) = @_;

  #RETRIEVE RESULTS FROM DB
        $ST_DB = $DB_edirect->prepare($query);
        $ST_DB->execute;
          
  #COUNT TOTAL MATCHING RESULTS 
        $count = $DB_edirect->selectrow_array("SELECT FOUND_ROWS()");
        $first_item = $form{ind} - 19;
        
  #DETERMINE NUMBER OF PAGES IN RESULTS
        $pages = $count / 20;
        $overflow = $count % 20;

  #DECLARE LOCAL VARIABLES FOR BINDING TO DB TABLE COLUMNS
        my ($prod_id, $model_num, $group_id, $descp, 
                  $size1, $size2, $finish, $unit, $price, $disc_qty, 
                  $stock, $qoh, $ship_time);  

        $ST_DB->bind_columns(\$prod_id, \$model_num, \$group_id, \$descp, 
                  \$size1, \$size2, \$finish, \$unit, \$price, \$disc_qty, 
                  \$stock, \$qoh, \$ship_time);     
                  
  #CALCULATE NUMBER OF ITEMS AND ROWS ON THIS PAGE, USE numRows AS LOOP CONTROL
  #FOR OUTSIDE for LOOP 
        if ($form{ind} > $count) {
                my $numItems = $count - ($form{ind} - 20);
                $numRows = sprintf("%1d", $numItems / 4);
                my $extraItems = $numItems % 4;
                if ($extraItems) {
                        $numRows++;
                }               
        } else {
                $numRows = 5;
        }
                
                                                                  

  #RETRIEVE mfg_id, mfg, coll_id, coll_name FROM DATABASE
        @collection_data = $DB2_edirect->selectrow_array("$coll_query");
                
  #IF THE COUNT OF ITEMS IS GREATER THAN 0 THEN DISPLAY 10 RESULTS      
        if ($count > 0) {
                print qq^<div id="subHeaderContainer"><div class="subHeader">$collection_data[1] - $collection_data[3]</div></div>
                      <div id="prodCollectionContainer">^;
                                
                if (-e "${home_dir}img/coll/pdf/$form{bid}/$form{bid}-$form{cid}\.pdf") {
                        print qq^<br>View entire collection in PDF format 
                                <a target="_blank" href="${img_url}coll/pdf/$form{bid}/$form{bid}-$form{cid}\.pdf">[click here]</a><br>^;
                }       
                
                if ($form{bid} == 700) {
                    print qq^<br><div style="font-weight:bold;color:#D20000;font-size:11pt;text-align:center">
		TOP KNOBS REQUIRES A SIGNATURE FOR ALL DELIVERIES</div>^;
                }                                         
                
                print qq^<div id="subHeader2Container">^;
                        
                if ($count > 1) {       
                        print qq^<span class="subHeader2">There are <b>$count</b> results matching your request. ^;
                } else {
                        print qq^<span class="subHeader2">There is <b>$count</b> result matching your request. ^;
                }
                
                if ($count != 1 && $form{ind} < $count) {
                        print qq^ Currently viewing items <b>$first_item</b> through 
                                <b>$form{ind}</b>.</span>^;
                } elsif ($count != 1 && $form{ind} > $count) {
                        print qq^Currently viewing items <b>$first_item</b> through 
                                <b>$count</b>.</span>^;
                } else {
                        print "</span>";
                }
                
                print qq^</div><div id="prodCollectionItemsContainer">^;

                while ($ST_DB->fetch()) {
                    print qq^<div class="prodCollectionItem"><div class="prodCollectionItemImage">^;
                                          
             ##DETERMINE IF THUMBNAIL IMAGE EXISTS AND DISPLAY, ELSE DISPLAY  
             ##IMAGE_NOT_AVAILABLE MESSAGE
                    my ($prod_image, $prod_image_url) = &get_prod_image("$prod_id", 'thmb');
                    my $image_info = image_info("$prod_image");  
                    my($w, $h) = dim($image_info); 
                    my $image_ratio = $w / $h;        
                    #              if (my $error = $info->{error}) {
                    #                  die "Can't parse image info: $error\n";
                    #              }
                    
                    if ($image_ratio > 1) {            
                       if ($w > 150) {
                           print qq^<a href="usastore.pl?a=di&pid=$prod_id">
                                         <img src="${prod_image_url}" width=150 border=0></a>^;
                       } else {
                           print qq^<a href="usastore.pl?a=di&pid=$prod_id"><img src="${prod_image_url}" width=$w border=0></a>^;
                       }
                    } elsif ($image_ratio < 1) {  
                       if ($h > 150) {
                           print qq^<a href="usastore.pl?a=di&pid=$prod_id">
                              <img src="${prod_image_url}" height=150 border=0></a>^;
                       } else {
                           print qq^<a href="usastore.pl?a=di&pid=$prod_id"><img src="${prod_image_url}" height=$h border=0></a>^; 
                       }
                    } else {  
                        if ($w < 150) {
                            print qq^<a href="usastore.pl?a=di&pid=$prod_id"><img src="${prod_image_url}" border=0></a>^; 
                        } else {
                            print qq^<a href="usastore.pl?a=di&pid=$prod_id"><img src="${prod_image_url}" width=150 border=0></a>^; 
                        }
                    
                    }          
                    
                    print "</div>";
                                       
                    if ($model_num ne '') {
                        print "$model_num";
                    } else {
                        print "$prod_id";
                    }
                        
                    print qq^<br>$descp^;
                                        
                   if ($group_id ne '') {
                       my ($size_count) = $DB_edirect->selectrow_array("SELECT count(DISTINCT size1) FROM products WHERE group_id = '$group_id'");
                       my ($finish_count) = $DB_edirect->selectrow_array("SELECT count(DISTINCT finish) FROM products WHERE group_id = '$group_id'");      
                       if ($size_count > 1) {                                                            
                            print qq^<div style="font-size:7pt;font-weight:bold;margin-top:10px;margin-bottom:10px">AVAILABLE IN SEVERAL SIZES</div>^;
                       } else {
                            print qq^$size1<br>^;
                       }
                                              
                       if ($finish_count > 1) { 
                          print qq^<div style="font-size:7pt;font-weight:bold;margin-top:10px;margin-bottom:10px">AVAILABLE IN SEVERAL FINISHES</a></div>^;
                       } else {
                          print qq^$finish<br>^;
                       }
                    } else {
                        $price = sprintf("%.2f", $price);
                        print qq^ - $size1 - $finish<br><br>
                                  <div class="prodListingDetailMoreInfo" style="float:none;margin-left:80px">       
                                       <a href="${cgi_url}usastore.pl?a=di&pid=${prod_id}">more info</a></div>^;     
                    }                                         
                                        
#                        if ($spid && $spid ne 'NEW') {
#                                my $specPrice = &calcSpecial("$spid", "$list");
#                                $price = sprintf("%.2f", $list);
#                                print qq^<td align=right class=small><b><font color=#FF8040>
#                                \$$price</font> $unit</b>
#                                <b><font color="#EA0000">
#                                SPECIAL: \$$specPrice</font></b></td></tr>^;
#                        } else {
#                                $price = sprintf("%.2f", $price);
#                                print qq^<td align=right class=small nowrap>            
#                                        <b><font color="#FF8040">\$$price</font> $unit</b>
#                                                </td></tr>^;
#                        }       
#    
                        
#                        print qq^<form method=post action=usastore.pl>
#                                        <input type=hidden name=a value=cart_add>
#                                        <tr><td class=small height=20 nowrap>
#                                        QTY: <input type=text name=${prod_id}_qty value="" size=1 style="font-size:9pt"></td>
#                                        <td nowrap><input type=submit value=ADD class=formButton><a href=\"${cgi_url}usastore\.pl?a=di&pid=${prod_id}\" #style="padding-left:5px; font-weight:bold; font-size:8pt">VIEW</a>
#                                        </td></tr>^;
                                        
            #IF A CASE QUANTITY EXISTS THEN PRINT THE QTY DISCOUNT MESSAGE  
                    if ($disc_qty > 0) {
                      # if ($group_id ne '') {
                            print qq^<div style="font-size:9pt;color:#BF4451;margin-top:15px;margin-left:40px">
                                    DISCOUNTS AVAILABLE 
                                    </div>^;
                       #} else {
                       #     print qq^<div style="font-size: 9pt;color:#BF4451">
                       #             DISCOUNT ON $disc_qty OR MORE.  
                       #             </div>^;
                       #}
                    } 
    
            print "</div>";
            
            }
        
            print qq^</div></div><div style="clear:both">^;
            
            $ST_DB->finish();
        
        ##DETERMINE & PRINT PAGE CONTINUATION NAVIGATION        
                my $cont_url = $cgi_url . 'usacollect.pl?';      
                
            if ($count > 20) {
                &page_continuation($count, $form{ind}, "$cont_url");
            }
  
        
        
        print qq^</div><div class="collectionNav">
                  <button class="formButtonSmall" style="display:inline" onClick="history.back()">&lt; back</button>
                  <span><b>BRAND:</b>
                  <form method=post action=usacollect.pl>
                  <input type=hidden name=st value=1>
                  <select name=bid onChange="this.form.submit()" class=frmField>
                  <option value="$collection_data[0]">$collection_data[1]</option>^;
        
        foreach my $this_brand (@$brands) {
                my ($bid, $bname) = @$this_brand;
                print qq^<option value="$bid">$bname</option>^;
        }
        
        print qq^</select></form></span>
                  <span><b>COLLECTION:</b>
                  <form method=post action=usacollect.pl>
                  <input type=hidden name=st value=2>
                  <input type=hidden name=bid value=$form{bid}>
                  <select name=cid onChange="this.form.submit()" class=frmField>
                  <option>$collection_data[3]</option>^;
        
        $ST2_DB = $DB2_edirect->prepare("SELECT coll_id, coll_name FROM collections
                                                WHERE brand_id = $form{bid}
                                                ORDER BY coll_name ASC");
                                                                                        
        $ST2_DB->execute();
        
        while (my ($id, $name) = $ST2_DB->fetchrow_array()) {
                print qq^<option value="$id">$name</option>^;
        }
        $ST2_DB->finish();
        
        print qq^</select></form></span></div>^;       

                        
  #IF THERE AREN'T ANY PRODUCTS TP DISPLAY                      
        } else {
                &no_results();
        }

}
########################### END SUB display_page ##############################
###############################################################################

#################################################################################
######################### DISPLAY CATALOG PAGE SUBROUTINE #######################
######################### REVISED & RENAMED display_page2 #######################
sub display_page2 {
        my ($product_query, $coll_query, $count, $results, @collection_data, $first_item);
        
        ($product_query, $coll_query) = @_;
         
  #COUNT TOTAL MATCHING RESULTS 
        $ST_DB = $DB_edirect->prepare("$product_query");
        $ST_DB->execute;
        $results = $ST_DB->fetchall_arrayref();
        $count = $DB_edirect->selectrow_array("SELECT FOUND_ROWS()");
        $ST_DB->finish();
        $first_item = $form{ind} - 9;
        
  #DETERMINE NUMBER OF PAGES IN RESULTS
        $pages = $count / 10;
        $overflow = $count % 10;
      
        
  #RETRIEVE mfg_id, mfg, coll_id, coll_name FROM DATABASE
        @collection_data = $DB_edirect->selectrow_array("$coll_query");
        
  #IF A MATCH THEN DISPLAY RESULTS      
        if ($count > 0) {
        print qq^ <TR><TD align=center style="font-size: 14pt; font-weight: bold">
                                $collection_data[1] - $collection_data[3]
                                </TD></TR>
                                <TR><TD align=center>
                                <table border=0 cellpadding=5 cellspacing=0 width=700>
                                <tr><td class=detail align=center>
                                <img src="${img_url}coll/$collection_data[0]-$collection_data[2]\.jpg">
                                </td></tr>
                                ^;

                print qq^
                        </td></tr> 
                        </table>
                        </TD></TR>
                        
                        <TR><TD colspan=2 align=center>
                        <table border=1 bordercolor=#000000 cellpadding=5 cellspacing=0 width=700>
                        <tr><th class=detail>
                        PRODUCT ID</th>
                        <th class=detail>DESCRIPTION</th>
                        <th class=detail>SIZE</th>
                        <th class=detail>FINISH</th>
                        <th class=detail colspan=2>PRICE</th></tr>^;
                  
        foreach $result (@$results) {
        ($prod_id, $model, $group_id, $descp, $size1, $size2, $finish, $unit, $price, $disc_qty, $stock, $qoh, $ship_time) = @$result;

                print qq^ <tr>
                                <td class=detailMfg bgcolor="#30507F">
                                <b>${prod_id}</b></td>
                                <td class=detail bgcolor=#D5D9E6>
                                <a href="${cgi_url}usastore.pl?a=di&pid=${prod_id}"><b>$descp</b></a></td>
                                <td class=detail bgcolor=#D5D9E6>
                                <b>$size1</b></td>
                                <td class=detail bgcolor=#D5D9E6>
                                <b>$finish</b></td>
                                <td class=detail>
                                <a href="${cgi_url}usastore.pl?a=di&pid=${prod_id}"><b>details</b></a>
                                </td>^;
                
#                if ($spid && $spid ne 'NEW') {
#                        my $specPrice = &calcSpecial("$spid", "$price");
#                        $price = sprintf("%.2f", $price);
#                        print qq^<td align="right" class="detail">
#                        <b><font color=#FF8040>
#                        \$$price</font> $unit</b>
#                        <b><font color="#EA0000">
#                        SPECIAL: \$$specPrice</font></b></td></tr>^;
#                } else {
                        $price = sprintf("%.2f", $price);
                        print qq^<td align=right class=detail>  
                                        <b><font color="#C50015">\$$price</font> $unit</b>
                                        </td></tr>^;
#                }
                
                        
        }  # END foreach
   
        
        
        
  ##DETERMINE & PRINT PAGE CONTINUATION NAVIGATION      
        my $cont_url = $cgi_url . 'usacollect.pl?bid=' . $form{bid} . '&st=' . $form{st} . '&cid=' . $form{cid} . '&ind=';      
                
                if ($count > 10 && $count > $form{ind} && $form{ind} > 10) {
                        my $last_page = $form{ind} - 20;
                        print qq^ <tr><td colspan=6>
                                                <table border=0 cellpadding=2 cellspacing=0 width=100%>
                                                <tr><td id=detail><a href="${cont_url}${last_page}">
                                                << PREVIOUS PAGE</a></td><td id=detail><b>PAGE:</b>^;
                                                
                        if ($pages <= 20) {                     
                                for ($i=0; $i<=$pages; $i++) {
                                        $page_ind = $i * 10;
                                        $p = $i + 1;
                                        print "| <a href=\"${cont_url}${page_ind}\">$p</a> ";
                                }
                                print "|";
                        } elsif ($pages <= 100) {                       
                                for ($i=4; $i<=$pages; $i+=5) {
                                        $page_ind = $i * 10;
                                        $p = $i + 1;
                                        print "| <a href=\"${cont_url}$page_ind\">$p</a> ";
                                }
                                print "|";      
                        } else {
                                for ($i=9; $i<=$pages; $i+=10) {
                                        $page_ind = $i * 10;
                                        $p = $i + 1;
                                        print "| <a href=\"${cont_url}${page_ind}\">$p</a> ";
                                }
                                print "|";
                        }                       
                        
                        print qq^</td><td align=right id=detail>                        
                                        <a href="${cont_url}$form{ind}">
                                                NEXT PAGE >></a></td></tr></table></td></tr>^;
                
                } elsif ($count > 10 && $count > $form{ind}) {
                        print qq^ <tr><td colspan=6 align=center>
                                                <table border=0 cellpadding=2 cellspacing=0 width=100%>
                                                <tr><td id=detail><b>PAGE:</b>^;

                        if ($pages <= 20) {                     
                                for ($i=0; $i<=$pages; $i++) {
                                        $page_ind = $i * 10;
                                        $p = $i + 1;
                                        print "| <a href=\"${cont_url}$page_ind\">$p</a> ";
                                }
                                print "|";
                        } elsif ($pages <= 100) {                       
                                for ($i=4; $i<=$pages; $i+=5) {
                                        $page_ind = $i * 10;
                                        $p = $i + 1;
                                        print "| <a href=\"${cont_url}$page_ind\">$p</a> ";
                                }
                                print "|";
                        } else {
                                for ($i=9; $i<=$pages; $i+=10) {
                                        $page_ind = $i * 10;
                                        $p = $i + 1;
                                        print "| <a href=\"${cont_url}$page_ind\">$p</a> ";
                                }
                                print "|";
                        }
                        
                        print qq^</td><td align=right id=detail>
                                        <a href=\"${cont_url}$form{ind}\">
                                                NEXT PAGE >></a></td></tr></table></td></tr> ^;
                
                } elsif ($count > 10 && $count < $form{ind})  {
                        my $last_page = $form{ind} - 20;
                        print qq^<tr><td colspan=6>
                                                <table border=0 cellpadding=2 cellspacing=0 width=100%>
                                                <tr><td id=detail><a href=\"${cont_url}$last_page\">
                                                << PREVIOUS PAGE</a></td><td id=detail align=right><b>PAGE:</b>^;
                        
                        if ($pages <= 20) {                     
                                for ($i=0; $i<=$pages; $i++) {
                                        $page_ind = $i * 10;
                                        $p = $i + 1;
                                        print "| <a href=\"${cont_url}$page_ind\">$p</a> ";
                                }
                                print "|";
                        } elsif ($pages <= 100) {                       
                                for ($i=4; $i<=$pages; $i+=5) {
                                        $page_ind = $i * 10;
                                        $p = $i + 1;
                                        print "| <a href=\"${cont_url}$page_ind\">$p</a> ";
                                }
                                print "|";      
                        } else {
                                for ($i=9; $i<=$pages; $i+=10) {
                                        $page_ind = $i * 10;
                                        $p = $i + 1;
                                        print "| <a href=\"${cont_url}$page_ind\">$p</a> ";
                                }
                                print "|";
                        }
                        
                        print qq^</tr></table></td></tr> ^;
                }                                       

                print qq^<tr><td align=center colspan=6 class="detail" bgcolor=#DD808C>
                                <table border=1 width=100% bordercolor=#000000 cellspacing=0 bgcolor=#DD808C>
                                                <tr><td align=center>
                                                 <button class=frmButtonSm onClick="history.back()">&lt; back</button>
                                                </td><form method=post action=usacollect.pl>
                                                <input type=hidden name=st value=1>
                                                <td align=center class=small><b>BRAND:</b>
                                                <select name=bid onChange="this.form.submit()" class=frmField>
                                                <option value="$collection_data[0]">$collection_data[1]</option>^;
        
        foreach my $this_brand (@$brands) {
                my ($bid, $bname) = @$this_brand;
                print qq^<option value="$bid">$bname</option>^;
        }
        
        print qq^</select></td></form><form method=post action=usacollect.pl>
                                                <input type=hidden name=st value=2>
                                                <input type=hidden name=bid value=$form{bid}>
                                                <td align=center class=small><b>COLLECTION:</b>
                                                <select name=cid onChange="this.form.submit()" class=frmField>
                                                <option>$collection_data[3]</option>^;
        
        $ST2_DB = $DB2_edirect->prepare("SELECT coll_id, coll_name FROM collections
                                                WHERE brand_id = $form{bid}
                                                ORDER BY coll_name ASC");
                                                                                        
        $ST2_DB->execute();
        
        while (my ($id, $name) = $ST2_DB->fetchrow_array()) {
                print qq^<option value="$id">$name</option>^;
        }
        $ST2_DB->finish();
        

        print qq^</select></td></form></tr></table></td></tr></table></TD></TR>^;
        
  ##END PAGE CONTINUATION NAVIGATION    
                        
  #IF THERE AREN'T ANY PRODUCTS TO DISPLAY                      
        } else {
                &no_results();
        }

}
########################### END SUB display_page2 ##############################
################################################################################


#################################################################################
#################### NO MATCHING RESULTS SUBROUTINE #############################
sub no_results {
        open(MAIL, "|/usr/sbin/sendmail -t");
        print MAIL "To: jon\@raugutt.com\n";
        print MAIL "Subject: USACABINETHARDWARE COLLECTIONS ERROR\n\n";
        print MAIL "COLLECTION ID: $form{cid}\n";
        close MAIL;

#       print qq^ <TR><TD colspan=2>
#                       <img src="${img_url}space.gif" width=400 height=15>
#                       </td></tr>
#                       <TR><TD colspan=2 align=center>
#                       <table border=1 bordercolor=#000000 cellpadding=5 cellspacing=0 width=400>
                        
#                       <tr><td align=center>
#                       <font size=4>
#                       <p>Sorry, the items for this collection are currently unavailable.
#                       </p></font>
#                       <br><br>
#                       <a href="javascript:history.back()">GO BACK</a>
#                       <img src=\"${img_url}warning.gif\">
#                       </td></tr>
#                       </table>
#                       </td></tr> ^;
}               
############################### END SUB no_results ##############################
#################################################################################

