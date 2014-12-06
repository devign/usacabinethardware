#!/usr/bin/perl

use DBI;

$base_url = 'http://www.usacabinethardware.com/';
$img_url = 'http://www.usacabinethardware.com/img/';
$cgi_url = 'http://www.usacabinethardware.com/cgi-bin/';
$secure_url = 'https://secure.usacabinethardware.com/';
$secure_cgi = 'https://secure.usacabinethardware.com/cgi-bin/';
$home_dir = '/vhosts/usacabinethardware.com/htdocs/';
#$home_dir = '/var/www/html/usa/';

$DB_edirect = DBI->connect('DBI:mysql:edirect:localhost:', 'edweb', 'gh0rAc', {
        RaiseError=>1,
        PrintError=>1
});
$DB2_edirect = DBI->connect('DBI:mysql:edirect:localhost:', 'edweb', 'gh0rAc', {
        RaiseError=>1,
        PrintError=>1
});

&parse();

$form{t} = 'knobSearch' if (!exists($form{t}));;

if (!$form{st} || $form{st} == 1) {
        my ($brands, $types, $finish, $style, $sizes, $query, $scid1, $scid2, $cid, $title);
        
        if ($form{t} eq 'knobSearch') {
                $cnid = 3800;
                $title = 'CABINET KNOBS & PULLS';
        } elsif ($form{t} eq 'hingeSearch') {
                $cnid = 3801;
                $title = 'HINGES';
        } elsif ($form{t} eq 'slideSearch') {
                $cnid = 3802;
                $title = 'DRAWER SLIDES';
        } elsif ($form{t} eq 'lockSearch') {
                $cnid = 3803;
                $title = 'CATCHES AND LOCKS';
        } elsif ($form{t} eq 'rackSearch') {
                $cnid = 3860;
                $title = 'COOKWARE RACKS';
        }
        
        $ST_DB = $DB_edirect->prepare("SELECT DISTINCT b.brand_id, brand
                                                FROM  store_sections ss, store_shelves ssh, prod_to_store pts, products p, brands b 
                                                WHERE ss.aisle_id = $cnid
                                                and ssh.section_id = ss.section_id
                                                and pts.shelf_id = ssh.shelf_id
                                                and p.prod_id = pts.prod_id
                                                and b.brand_id = p.brand_id
                                                ORDER BY brand");
        $ST_DB->execute();
        $brands = $ST_DB->fetchall_arrayref();
        
        $ST_DB = $DB_edirect->prepare("SELECT section_id, section_name
                                                FROM store_sections 
                                                WHERE aisle_id = $cnid
                                                ORDER BY section_id");
        $ST_DB->execute();        
        $style = $ST_DB->fetchall_arrayref();

        $ST_DB = $DB_edirect->prepare("SELECT DISTINCT finish
                                                FROM store_sections ss, store_shelves ssh, prod_to_store pts, products p
                                                WHERE ss.aisle_id = $cnid
                                                and ssh.section_id = ss.section_id
                                                and pts.shelf_id = ssh.shelf_id
                                                and p.prod_id = pts.prod_id
                                                ORDER BY finish");              
        $ST_DB->execute();                                                        
        $finish = $ST_DB->fetchall_arrayref();            
                                                
        $ST_DB = $DB_edirect->prepare("SELECT DISTINCT size1 
                                                FROM store_sections ss, store_shelves ssh, prod_to_store pts, products p
                                                WHERE ss.aisle_id = $cnid
                                                and ssh.section_id = ss.section_id
                                                and pts.shelf_id = ssh.shelf_id
                                                and p.prod_id = pts.prod_id
                                                and size1 is not null 
                                                ORDER BY size1");         
        $ST_DB->execute();                                                        
        $sizes = $ST_DB->fetchall_arrayref();     
        $ST_DB->finish();
         
        &page_header($title . 'Search');
        print qq^<form name=frmEDHSearch method=post action="usasearch.pl" onSubmit="this.btnSearchSubmit.value='SEARCHING...';this.btnSearchSubmit.disabled='true'">
                                <input type=hidden name=st value=3>
                                <input type=hidden name=t value="$form{t}">
                                <tr>
                <td style="padding:20px" colspan=5><h3 class=locHead>PREMIUM SEARCH->$title</h3></td></tr>
                <tr><td colspan=5 style="text-align:center">
                <table border=1 bgcolor="#FFFFFF" bordercolor="#E0E0E0" cellpadding=5 cellspacing=0 width=640 style="margin-bottom:20px">
                <tr>
                <td width=30% valign=top>
                        <table border=0 bgcolor=#FFFFFF cellpadding=5 cellspacing=0>
                        <tr><td class=small><b>INSTRUCTIONS:</b><br>
                Select your search options from the list menus.<br><br>
                For a <b>broader search</b>,  
                leave options set to ANY.<br><br>
                 After making your choices, click the "<b>GET RESULTS</b>" button to see the items currently available.
                        </td>
                        </tr>
                        </table>
                </td>
                <td class=detail>         
                        <table border=0 cellpadding=3 cellspacing=0 width=100%>
                        <tr>
                        <td class="detail" style="padding-bottom:10px">
                        <b>BRAND:</b><br> <select name=bid>^;
        if (exists($form{bid}) && $form{bid} ne 'ANY') {
                foreach $brandRec (@$brands) {
                        if (@$brandRec[0] eq "$form{bid}") {
                                print qq^<option value="@$brandRec[0]">@$brandRec[1]</option>^;
                        }
                }
        }
                print qq^<option value=ANY>ANY</option>^;
        
        foreach $brandRec (@$brands) {
                print qq^<option value="@$brandRec[0]">@$brandRec[1]</option>^;
        }
        print qq^</select></td><td class=detail colspan=2>^;
        
#                       <b>Description:</b><br> <select name=descp>^;
#       if (exists($form{descp}) && $form{descp} ne 'ANY') {
#               print "<option value=\"$form{descp}\">$form{descp}</option>";
#       }               
#       print qq^<option value=ANY>ANY</option>^;
#                       
#       foreach $typesRec (@$types) {
#               print qq^<option value="@$typesRec[0]">@$typesRec[0]</option>^;
#       }
        print qq^</td></tr>
                        <tr><td class=detail style="padding-bottom:10px"><b>FINISH:</b><br>
                        <select name=finish>^;
        if (exists($form{finish}) && $form{finish} ne 'ANY') {
                print "<option value=\"$form{finish}\">$form{finish}</option>";
        }               
        print qq^<option value=ANY>ANY</option>^;
        
        foreach $finRec (@$finish) {
                print qq^<option value="@$finRec[0]">@$finRec[0]</option>^;
        }
        print qq^</select></td></tr><tr><td class=detail style="padding-bottom:10px">
                        <b>TYPE:</b><br> <select name=cnid>^;
                        
        if (exists($form{cnid}) && $form{cnid} ne 'ANY') {
                foreach $styleRec (@$style) {
                        if (@$styleRec[0] eq "$form{cnid}") {
                                print qq^<option value="@$styleRec[0]">@$styleRec[1]</option>^;
                        }
                }
        }               
        
        print qq^<option value=ANY>ANY</option>^;       
        
        foreach $styleRec (@$style) {
                print qq^<option value="@$styleRec[0]">@$styleRec[1]</option>^;
        }
        
        print qq^</select></td></tr><tr><td class=detail style="padding-bottom:10px">
                  <b>SIZE:</b><br> <select name=size>^;
        
        if (exists($form{size}) && $form{size} ne 'ANY') {
                print "<option value=\"$form{size}\">$form{size}</option>";
        }
        
        print qq^<option value=ANY>ANY</option>^;
        
        foreach $sizesRec (@$sizes) {
                if (@$sizesRec[0] ne 'n/a') {
                        my $dispSize = @$sizesRec[0];
                        @$sizesRec[0] =~ s/"/in/g;
                        print qq^<option value="@$sizesRec[$i]">$dispSize</option>^;
                }
        }
        
        print qq^</select></td></tr>            
                        <tr><td align=center style="padding-top:30px">
                        <input type=submit name=btnSearchSubmit value="GET RESULTS" class="frmButton">
                        </td>
                        </tr>           
                        </form>
                        </table>
                </td>
                </tr>
                </table>^;
        
        &page_footer();
        
        
} elsif ($form{st} == 3) {
        my ($query, $count_query, $cid1, $cid2);
        
        $query = "SELECT SQL_CALC_FOUND_ROWS DISTINCT b.brand_id, brand, model_num, 
                group_id, p.prod_id, detail_descp, size1, size2, finish, unit, 
                price, disc_qty
                FROM store_sections AS ss
                LEFT JOIN store_shelves AS ssh USING(section_id)
                LEFT JOIN prod_to_store AS pts USING(shelf_id)
                LEFT JOIN products AS p USING(prod_id)
                LEFT JOIN brands AS b USING(brand_id)";
               
        if ($form{t} eq 'knobSearch') {
                $cnid = 3800;
                $title = 'CABINET KNOBS & PULLS';
        } elsif ($form{t} eq 'hingeSearch') {
                $cnid = 3801;
                $title = 'HINGES';
        } elsif ($form{t} eq 'slideSearch') {
                $cnid = 3802;
                $title = 'DRAWER SLIDES';
        } elsif ($form{t} eq 'lockSearch') {
                $cnid = 3803;
                $title = 'CATCHES AND LOCKS';
        } elsif ($form{t} eq 'rackSearch') {
                $cnid = 3860;
                $title = 'COOKWARE RACKS';
        }        

    if ($form{user_term}) {
        $form{user_term} =~ s/^O*/0/i;
        $query .= " WHERE p.prod_id like '%$form{user_term}%'";
    
    } else {
                                        
        $query .= " WHERE";
       
        if ($form{bid} ne 'ANY' || $form{finish} ne 'ANY' ||
                $form{cnid} ne 'ANY' || $form{size} ne 'ANY') {

                if (exists($form{bid}) && $form{bid} ne 'ANY') {
                        $query .= " b.brand_id = $form{bid}";
                } 
                
 #              if (exists($form{descp}) && $form{descp} ne 'ANY') {
 #                      if (substr("$query", -5) eq 'WHERE') {
 #                              $query .= " detail_descp = '$form{descp}'";
 #                              $count_query .= " detail_descp = '$form{descp}'";
 #                      } else {
 #                              $query .= " and detail_descp = '$form{descp}'";         
 #                              $count_query .= " and detail_descp = '$form{descp}'";           
 #                      }
 #              } 
                
                if (exists($form{finish}) && $form{finish} ne 'ANY') {
                        if (substr("$query", -5) eq 'WHERE') {
                                $query .= " finish = '$form{finish}'";
                        } else {
                                $query .= " and finish = '$form{finish}'";      
                        }                       
                } 
                
                if (exists($form{cnid}) && $form{cnid} ne 'ANY') {
                        if (substr("$query", -5) eq 'WHERE') {
                                $query .= " ss.section_id = $form{cnid}";
                        } else {
                                $query .= " and ss.section_id = $form{cnid}";              
                       }                       
                } 
                
                 
                
                if (exists($form{size}) && $form{size} ne 'ANY') {
                        my $searchSize = $form{size};
                        $searchSize =~ s/in/"/g;
                        $searchSize = $DB_edirect->quote("$searchSize");
                        if (substr("$query", -5) eq 'WHERE') {
                                $query .= " size1 = $searchSize";
                        } else {
                                $query .= " and size1 = $searchSize";   
                        }                       
                }
        } else {
                if (exists($form{cnid}) && $form{cnid} eq 'ANY') {
                        if (substr("$query", -5) eq 'WHERE') {
                                $query .= " ss.aisle_id = $cnid";
                        } else {
                                $query .= " and ss.aisle_id = $cnid";            
                        }                       
                }
        }
    }   
        
        $query .= " and status != 0                    
                  GROUP BY group_id, model_num";

        if (exists($form{ind}) && $form{ind} != 0) {
                $query .= " LIMIT $form{ind}, 20";
                $form{ind} += 20;
        } else {
                $form{ind} = 20;
                $query .= " LIMIT 20";
        }
        

        &page_header("$title");
        &display_page($query);    
        &page_footer(); 
}


$DB_edirect->disconnect();

exit(0);


#################################################################################
######################### DISPLAY CATALOG PAGE SUBROUTINE #######################
sub display_page() {
        my ($query, $count_query, @count, $results, $first_item, $numRows);
        
        $query = shift @_;

  #RETRIEVE RESULTS FROM DB
        $ST_DB = $DB_edirect->prepare($query);
        $ST_DB->execute;
       
                         
  #COUNT TOTAL MATCHING RESULTS 
        $count = $DB_edirect->selectrow_array("SELECT FOUND_ROWS()");
        $first_item = $form{ind} - 19;
        
  #DETERMINE NUMBER OF PAGES IN RESULTS
        $pages = $count / 20;
        $overflow = $count % 20;

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

  #IF THE COUNT OF ITEMS IS GREATER THAN 0 THEN DISPLAY 20 RESULTS      
        if ($count > 0) {
        
          #RETRIEVE RESULTS FROM DB
                # DECLARE LOCAL VARIABLES FOR BINDING TO DB TABLE COLUMNS
                my ($bid, $brand, $model_num, $group_id, $prod_id, $descp, $size1, 
                        $size2, $finish, $unit, $price, $disc_qty);  
                $ST_DB->bind_columns(\$bid, \$brand, \$model_num, \$group_id, 
                        \$prod_id, \$descp, \$size1, \$size2, \$finish, \$unit, \$price, \$disc_qty);                                                                          

                print qq^<tr><td style="text-align:center">
                                <table border=0 cellpadding=5 cellspacing=0 width=700>
                                <tr><td class=detail>
                                To view a larger image and detail description of an item, click 
                                the     <b>"VIEW"</b> link or the item image.  To add any 
                                item to your cart, enter the quantity you want then click the 
                                <font color="#C50015">red</font>
                                <b>\"ADD\"</b> button. After adding to your cart you will 
                                be shown the items currently in your cart.<br><br>^;
                        
                if ($count > 1) {       
                        print "<i>There are <b>$count</b> results matching your request. ";
                } else {
                        print "<i>There is <b>$count</b> result matching your request. ";
                }
                
                if ($count != 1 && $form{ind} < $count) {
                        print qq^ Currently viewing items <b>$first_item</b> through 
                                <b>$form{ind}</b>.</i>^;
                } elsif ($count != 1 && $form{ind} > $count) {
                        print qq^Currently viewing items <b>$first_item</b> through 
                                <b>$count</b>.</i>^;
                } else {
                        print "</i>";
                }
                
                print qq^
                        </td></tr> 
                        </table>
                        </TD></TR>
                        
                        <TR><TD style="text-align:center">
                        <table border=0 bordercolor=#000000 cellpadding=0 cellspacing=0 width=740>^;

        for ($i=0; $i<$numRows; $i++) {

                print qq^ <tr>^;
                for ($n=0; $n<4; $n++) {
                        if ($ST_DB->fetch()) {
                                print qq^<td width=185>
                                        <table border=1 bordercolor=#000000 cellpadding=3 cellspacing=0 width=100%>
                                        <tr><td style="text-align:center" colspan=2 height=70>       ^;
        ##DETERMINE IF IMAGE EXISTS AND DISPLAY, ELSE DISPLAY IMAGE_NOT_AVAILABLE
                        if (-e "${home_dir}img/thmb/${bid}/thmb-${prod_id}\.jpg") {
                                print "<a href=\"${cgi_url}usastore\.pl?a=di&pid=${prod_id}\">\n
                                           <img src=\"${img_url}thmb/${bid}/thmb-${prod_id}\.jpg\" height=70 border=0></a>";
                        } elsif (-e "${home_dir}img/thmb/${bid}/thmb-${group_id}\.jpg") {
                                print "<a href=\"${cgi_url}usastore\.pl?a=di&pid=${prod_id}\">\n
                                           <img src=\"${img_url}thmb/${bid}/thmb-${group_id}\.jpg\" height=70 border=0></a>";
                        } else {
                                print "<a href=\"${cgi_url}usastore\.pl?a=di&pid=${prod_id}\"><div style=\"font-size:8px\">NO IMAGE AVAILABLE</div></a>";
                        }  
                        

                    
                       print qq^ </td></tr>
                                        <tr>    
                                        <td class=detailMfg bgcolor="#30507F" colspan=2 height=10>
                                        ${prod_id}
                                        </td>
                                        </tr>
                                        <tr>
                                        <td class=small height=50><b>$descp</b></a></td>^;
                                        
                    if ($group_id ne '') {
                         my ($size_count, $gar) = $DB_edirect->selectrow_array("SELECT count(DISTINCT size1) FROM products WHERE group_id = '$group_id'");
                         my ($finish_count, $gar) = $DB_edirect->selectrow_array("SELECT count(DISTINCT finish) FROM products WHERE group_id = '$group_id'
");      
                         if ($size_count > 1) {                                                            
                              print qq^<td><span style="font-size:7pt;font-weight:bold">
                                      <a href=\"${cgi_url}usastore.pl?a=di&pid=${prod_id}\">VIEW OPTIONS</a></span></td></tr>^;
                         } else {
                              print qq^<td class=small>$size1</td></tr>^;
                         }
                         
                         if ($finish_count > 1) { 
                            print qq^<td><span style="font-size:7pt;font-weight:bold">
                                    <a href=\"${cgi_url}usastore.pl?a=di&pid=${prod_id}\">VIEW OPTIONS</a></span></td>^;
                         } else {
                            print qq^ <td class=small height=40>$finish</td>^;
                         }
                    } else {
                        print qq^<td class=small>$size1</td></tr>
                                        <tr>
                                        <td class=small height=40>$finish</td>^;
                    }
                                                            
       
#                        if ($spid && $spid ne 'NEW') {
#                                my $specPrice = &calcSpecial("$spid", "$list");
#                                $price = sprintf("%.2f", $price);
#                                print qq^<td align=right class=small><b><font color=#FF8040>
#                                \$$price</font> $unit</b>
#                                <b><font color="#EA0000">
#                                SPECIAL: \$$specPrice</font></b></td></tr>^;
#                        } else {
                                $price = sprintf("%.2f", $price);
                                print qq^<td align=right class=small nowrap>            
                                        <b><font color="#FF8040">\$$price</font> $unit</b>
                                                </td></tr>^;
#                        }       
    
                        
                        print qq^<form method=post action=usastore.pl>
                                        <input type=hidden name=a value=cart_add>
                                        <tr><td class=small height=20 nowrap>
                                        QTY: <input type=text name=${prod_id}_qty value="" size=3></td><td nowrap><input type=submit value=ADD class=formButton><a href=\"${cgi_url}usastore.pl?a=di&pid=${prod_id}\" style="padding-left:5px; font-weight:bold; font-size:8pt">VIEW</a>
                                        </td></tr>^;
                                        
                #IF A CASE QUANTITY EXISTS THEN PRINT THE QTY DISCOUNT MESSAGE  
                        if ($disc_qty > 0) {
                                print qq^               
                                        <tr><td class=tiny colspan=2 height=15><font color=\"#BF4451\">
                                        DISCOUNT ON $disc_qty OR MORE.  
                                        <font size=1>(Discount calculated in cart)</font></font>
                                        </td></tr>^;
                        } 
    
                
                                print qq^</table> </form>
                                        </td>^;

                        } else {
                                        last;
                                }# END MAIN IF          
                }  # END for LOOP THAT PRINTS EACH CELL
                        print "</tr>";
        } # END for LOOP THAT PRINTS EACH ROW
        
        $ST_DB->finish();
        
  ##DETERMINE & PRINT PAGE CONTINUATION NAVIGATION        
        print "</td></tr></table></td></tr><tr><td>";
        
        if ($count > 20) {
            &page_continuation($count, $form{ind});
        }
        
        print "</td></tr>";
        
  ##END PAGE CONTINUATION NAVIGATION    
                        
  #IF THERE AREN'T ANY PRODUCTS TO DISPLAY                      
        } else {
                &no_results();
        }

}
########################### END SUB display_page ##############################
###############################################################################

################################################################################
####################### NO MATCHING RESULTS SUBROUTINE #########################
sub no_results() {
        my $msg;
        
        if ($form{user_term}) {
                $msg = "I can't find the item number you specified.  Item numbers 
                                usually vary from seller to seller in some small way.  For 
                                instance, the Amerock part number 4425-RBZ translates to
                                639-4425-RBZ in our database, but could be something else on 
                                another site or in a retail store such as BP4425-RBZ or 
                                AMBP4425-RBZ or AME-4425-RBZ, I'm sure you get the picture.  
                          However, 
                                notice that the 4425-RBZ is the same in all four.  If you try
                                your search without the first character or two (or even just
                                the core number 4425), you may find     what you are looking for.";
        } else {
                $msg = "I can't find any items matching the parameters you specified.  
                        It could be that the finish, size, style or description (or 
                        combination) that you have chosen is not offered by the 
                        manufacturer 
                        selected.  You may want to 
                        broaden your selective-search by setting some of the parameters to 
                        \"ANY\", you can do so by clicking the \"ADJUST THIS ... SEARCH\" 
                        link below this message box.";
        }  
                                
        print qq^ <tr><td align=center>
                        <table cellpadding=20 cellspacing=0 width=600>
                        
                        <tr><td align=center><b>
                        <p>$msg</p>
                        
                        <p>If you are still getting this message and can't find what you are 
                        looking for, please 
                        <a href=\"mailto:service\@usacabinethardware.com?Subject=Search_Problems\">e-mail</a> us and we will get back to you
                        in 24 to 48 hours.</p>
                        <br>
                        
                        </td></tr>
                        </table>
                        </td></tr> ^;
}               
############################## END SUB no_results ##############################
################################################################################

#################################################################################
############################ PAGE CONTINUATION SUBROUTINE #######################
sub page_continuation() {
    my ($current_page, $total_item_count, $current_index, $previous_page, @low_pages, 
        @hi_pages, $next_page, $total_pages, $first_page_url, $previous_page_url,
        $next_page_url, $last_page_url);
    
    ($total_item_count, $current_index) = @_;
    
   
  ##DETERMINE & PRINT PAGE CONTINUATION NAVIGATION        
    $cont_url = $cgi_url . 'usasearch.pl?t=' . $form{t} . '&st=3';
        
    if ($form{did}) {
            $cont_url .= '&did=' . $form{did};
    }
    if ($form{cnid}) {
            $cont_url .= '&cnid=' . $form{cnid};
    }    
    if ($form{finish}) {
            $form{finish} =~ s/\s/+/g;
            $cont_url .= '&finish=' . $form{finish};
    } 
    if ($form{bid}) {
            $cont_url .= '&bid=' . $form{bid};
    }
    if ($form{size}) {
            $form{size} =~ s/\s/+/g;
            $cont_url .= '&size=' . $form{size};
    }
    if ($form{descp}) {
            $form{descp} =~ s/\s/+/g;
            $cont_url .= '&descp=' . $form{descp};
    }
    if ($form{search_value}) {
            $form{search_value} =~ s/\s/+/g;                        
            $cont_url .= '&search_value=' . $form{search_value};
    }    
    if ($form{sortBy}) {
        $cont_url .= '&sortBy=' . $form{sortBy};
    }                   
                
    $cont_url .= '&ind=';

    $current_page = $current_index / 20;

    $first_page_url = $cont_url . '0';
        
    if ($total_item_count % 20 != 0) {
        $total_pages = sprintf("%1d", $total_item_count / 20 + 1);
    } else {
        $total_pages = $total_item_count / 20;
    }    

    $last_page_url = $cont_url . (($total_pages - 1) * 20);     
    
    for (1 .. 4) {
        unshift @low_pages, $current_page - $_;
        if (($current_page + $_) <= $total_pages) {
            push @hi_pages, $current_page + $_;
        }
    }
                 
    print qq^ <div class="continuation">^;

    if ($current_page != 1) {    
        $previous_page = ($current_page - 2) * 20;
        $previous_page_url = $cont_url . $previous_page;
        
        if ($current_page != $total_pages) {
            $next_page = $current_page   * 20;
            $next_page_url = $cont_url . $next_page;
        }
        
        print qq^<span class="continueLastButton">
                      <a style="text-decoration:none" href="$first_page_url">
                                <b><< FIRST PAGE</b></a></span>
                      <span class="continueLastButton">
                        <a style="text-decoration:none" href="$previous_page_url">
                          <b>< PREVIOUS PAGE</b></a></span>
                          <div id="pageSelect">^;
    
                  
        foreach (@low_pages) {
            if ($_ > 0) {
                my $this_index = $_ * 20 - 20; 
                my $this_url = $cont_url . $this_index;
                print qq^<span style="margin-right:20px"><a href="$this_url">$_</a></span>^;
            }
        }
    } else {
       
        $next_page = $current_page * 20;
        $next_page_url = $cont_url . $next_page;

        print qq^<span class="continueLastButtonOff"><< FIRST PAGE</span>
                 <span class="continueLastButtonOff">< PREVIOUS PAGE</span>
                          <div id="pageSelect">^;
    
    }        
    
    print qq^<span id="currentPage">$current_page</span>^;
    
    foreach (@hi_pages) {
        my $this_index = $_ * 20 - 20; 
        my $this_url = $cont_url . $this_index;
        print qq^<span style="margin-left:20px"><a href="$this_url">$_</a></span>^;
    }    
    
    if ($current_page != $total_pages) {
        print qq^</div><span class="continueNextButton">
              <a style="text-decoration:none" href="$next_page_url">NEXT PAGE ></a></span>
                  <span class="continueNextButton">
                  <a style="text-decoration:none" href="$last_page_url">LAST PAGE >></a></span></div>^;
                  
    } else {
        print qq^</div><span class="continueNextButtonOff">NEXT PAGE ></span>
                  <span class="continueNextButtonOff">LAST PAGE >></span></div>^;
    }                

  ##END PAGE CONTINUATION NAVIGATION    
}
############################ END page_continuation SUB #########################
################################################################################

#################################################################################
############################# PAGE FOOTER  SUBROUTINE ###########################
sub page_footer() {
        if ($form{t} eq 'knobSearch') {
                $title = 'KNOBS AND PULLS';
        } elsif ($form{t} eq 'hingeSearch') {
                $title = 'HINGES';
        } elsif ($form{t} eq 'slideSearch') {
                $title = 'DRAWER SLIDES';
        } else {
                $title = 'CATCHES AND LOCKS';
        }
        
        if ($form{st} == 3) {
                print qq^
                        <tr>            
                        <td style="padding-top:10px;padding-bottom:10px;font-size:10pt;font-weight:bold;text-align:center">^;
        
                if (!$form{user_term}) {
                        print qq^
        <a href="usasearch.pl?t=$form{t}&bid=$form{bid}&descp=$form{descp}&finish=$form{finish}&cnid=$form{cnid}&size=$form{size}" style="padding-left:15px">ADJUST THIS $title SEARCH</a>^;
                }
        
        print qq^
        <a href="usasearch.pl?t=$form{t}" style="padding-left:15px">NEW $title SEARCH</a>
        <br>
        <a href="usasearch.pl?st=1" style="padding-left:15px">NEW SELECTIVE SEARCH</a>
        </td></tr>^;
        }
        
        print qq^<tr><td class="footNav">
| <a href="${base_url}index.html">Home</a> |
| <a href="${base_url}knobs-pulls.phtml">Knobs & Pulls</a> |
| <a href="${base_url}hinges.phtml">Cabinet Hinges</a> |
| <a href="${base_url}drawer-slides.phtml">Drawer Slides</a> |
| <a href="${base_url}catches-locks.phtml">Catches & Locks</a> |
| <a href="${base_url}customer-care.html">Customer Care</a> |
| <a href="${base_url}contact.html">Contact</a> |
| <a href="${base_url}search.html">Search</a> |
</td>
</tr>
<tr><td style="text-align:center" class="tiny">
Copyright &copy; 2006-2009 usacabinethardware.com by Everything Direct<br>
1046 39th Ave W<br>
West Fargo, ND 58078<br>
1.877.281.7905<br>
<a href="mailto:webadmin@usacabinethardware.com">webadmin</a>
<br><br>
</td></tr>
</table>
        
</body>
</html>^;

} 
########################## END page_footer SUBROUTINE ###########################
#################################################################################

#################################################################################
############################ PAGE HEADER  SUBROUTINE ############################
sub page_header() {

        print "Content-type: text/html\n\n";

        print qq^ <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
              <HTML><HEAD><TITLE>USA CABINET HARDWARE - HARDWARE COLLECTIONS</TITLE>^;
        
        print qq^<link rel=\"StyleSheet\" href=\"${base_url}main.css\">
                        <SCRIPT src=${base_url}usa.js></script> ^;

        print qq^<meta name="description" content="Cabinet hardware from Amerock, Belwith-Keeler, Berenson, Liberty Hardware and others. Knobs, pulls, hinges and catches for your cabinet hardware.">
<meta name="keywords" content="cabinet hardware, Amerock, Belwith-Keeler, Berenson, Liberty Hardware, cabinet knobs, cabinet pulls, cabinet hinges, drawer pulls, drawer knobs, drawer handles, cabinet handles, kitchen cabinet hinges, kitchen cabinet hardware, catches.">
</head>
<body>

<table bgcolor="#FFFFFF" align="center" width="780" border="0" cellpadding="0" cellspacing="0">
<tr>
<td>
<img name="head" src="${img_url}head.gif" width="780" height="76" border="0" usemap="#m_head">
<map name="m_head">
<area shape="rect" coords="310,39,404,57" href="${cgi_url}usastore.pl?a=cart_display" alt="" >
<area shape="rect" coords="413,40,527,57" href="https://secure.usacabinethardware.com/cgi-bin/usastore.pl?a=cart_checkout" alt="" >
<area shape="rect" coords="539,41,668,55" href="${base_url}customer-care.html" alt="" >
<area shape="rect" coords="681,40,775,56" href="${base_url}contact.html" alt="" >
<area shape="rect" coords="691,12,780,33" href="${base_url}search.html" alt="" >
<area shape="rect" coords="452,11,618,30" href="${base_url}catches-locks.phtml" alt="" >
<area shape="rect" coords="312,11,445,30" href="${base_url}drawer-slides.phtml" alt="" >
<area shape="rect" coords="238,12,307,29" href="${base_url}hinges.phtml" alt="" >
<area shape="rect" coords="79,11,230,29" href="${base_url}knobs-pulls.phtml" alt="" >
<area shape="rect" coords="0,4,74,48" href="${base_url}index.html" alt="" >
</map>

</td>
</tr>^;

                        
} 
########################### END page_header SUBROUTINE ##########################
#################################################################################

################################################################################
############################# FORM PARSE SUBROUTINE ############################
sub parse() {
if ($ENV{'REQUEST_METHOD'} eq 'GET') {
        @pairs = split(/&/, $ENV{'QUERY_STRING'});
} elsif ($ENV{'REQUEST_METHOD'} eq 'POST') {
        read (STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
        @pairs = split(/&/, $buffer);
} else {
        print "Content-type: text/html\n\n";
        print "<P>Use Post or Get";
}

foreach $pair (@pairs) {
        ($key, $value) = split (/=/, $pair);
        $key =~ tr/+/ /;
        $key =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $value =~ tr/+/ /;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        
        $value =~s/<!--(.|\n)*-->//g;
        
        if ($form{$key}) {
                $form{$key} .= ", $value";
        } else {
                $form{$key} = $value;
        }
}
}
################################## END SUB parse ###############################
################################################################################
