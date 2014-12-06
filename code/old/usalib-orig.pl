#################################################################################
######################## CALCULATE DISCOUNT SUBROUTINE ##########################
sub calcDiscount() {
    my ($qty, $price, $disc_amt) = @_;
        
    my $total_price = $qty * $price;
    my $item_disc = sprintf("%.2f", $total_price * $disc_amt);
    return $item_disc;

}
############################# END CALCULATE DISCOUNT ############################
#################################################################################

#################################################################################
################### CALCULATE ORDER NOW DISCOUNT SUBROUTINE #####################
sub calcOrderNowDiscount() {
    my ($sub_total, $session_id, $existing_discount, $ON_discount_mult, $ITEMS);
    
    ($sub_total, $session_id, $existing_discount) = @_;
    
    if ($sub_total >= 100 && $sub_total < 250) {
 #       $ON_discount_mult = .05;
    } elsif ($sub_total >= 250 && $sub_total < 500) {   
 #       $ON_discount_mult = .07;    
    } elsif ($sub_total >= 1000 && $sub_total < 1500) { 
        $ON_discount_mult = .1;    
    } elsif ($sub_total >= 1500 && $sub_total < 2000) { 
        $ON_discount_mult = .125;     
    } elsif ($sub_total >= 2000 && $sub_total < 3000) {  
        $ON_discount_mult = .15;    
    } elsif ($sub_total >= 3000) {
        $ON_discount_mult = .175;    
    }
    
#    $ST_DB = $DB_edirect->prepare("SELECT prod_id, dept_id FROM cart c, prod_to_cat ptc, categories ca
#                          WHERE session_id = $session_id
#                          and site_id = $site_id
#                          and ptc.prod_id = c.prod_id
#                          and c.cat_id = ptc.cat_id");
#    $ST_DB->execute();
#    $ITEMS = $ST_DB->fetchall_arrayref();
#    $ST_DB->finish();
    
#    foreach $ITEM (@$ITEMS) {
#        my ($pid, $did) = @$ITEM;
#        if ($did == 247 || $did == 248) {
#            $ON_discount_mult -= .02;
#        }
#    }

    $ON_discount = sprintf("%.2f", $sub_total * $ON_discount_mult);
    
    if ($existing_discount > 0) {
        $ON_discount = 0;
    }
    
    return $ON_discount;

#      return 0;
}
######################### END CALC ORDER NOW DISCOUNT ###########################
#################################################################################

#################################################################################
######################## CALCULATE SPECIAL SUBROUTINE ###########################
sub calcSpecial() {
        my ($spid, $cur_price) = @_;
        
        my $spec_rate = $DB_edirect->selectrow_array("SELECT spec_discount 
                                FROM specials
                                WHERE site_id = $site_id
                                and spec_id = $spid");
                                
        if ($spec_rate < 1) {
                my $discount = $cur_price * $spec_rate;
                $cur_price -= $discount;
        } else {
                $cur_price -= $spec_rate;
        }
        
        $cur_price = sprintf("%.2f", $cur_price);
        
    return $cur_price;

}
############################# END CALCULATE SPECIAL #############################
#################################################################################

    
    
############################################################################### 
############################# CALCULATE SHIPPING SUBROUTINE ###################
sub calc_shipping() {
    my($total_weight, $ship_rate, $zip, $zone, $ship_method,
                            $rate_chart, $vend_weights, $order_total);
    
    $ship_method = pop @_;
    
    if (!defined($order_total) || $order_total eq '') {
             $order_total = $DB_edirect->selectrow_array("SELECT sum(c.qty * p.price)
                            FROM cart c, products p
                            WHERE c.session_id = '$session_id'
                            and c.site_id = $site_id
                            and p.prod_id = c.prod_id
                            GROUP BY session_id");
    
    }                             
    
    #        $ST_DB = $DB_edirect->prepare("SELECT c.vend_id, sum(c.qty * p.weight)
    #                                FROM cart c, products p
    #                                WHERE c.session_id = '$session_id'
    #                                and c.prod_id = p.prod_id
    #                                GROUP BY c.vend_id");
    #        $ST_DB->execute();
    #        $vend_weights = $ST_DB->fetchall_arrayref();
    #        $ST_DB->finish();
    
    $ship_rate = 0;
    
    $zip = substr($form{cust_szip}, 0, 3);
        
 if ($form{cust_sctry} eq 'us') {      
    
     
   ##DETERMINE ZONE AND RATE CHART FOR UPS SHIPPING     
        if ($ship_method eq 'GROUND') {
                $zone = $DB_edirect->selectrow_array("SELECT ground FROM UPS_US_zone
                                                WHERE $zip between zip1 and zip2
                                                OR zip1 = $zip");

                $zone = 'G' . $zone;
                
                $rate_chart = 'UPS_US_ground';
                
        } elsif ($ship_method eq '3DAY')      {
                $zone = $DB_edirect->selectrow_array("SELECT 3day_select FROM UPS_US_zone
                                                WHERE $zip between zip1 and zip2
                                                OR zip1 = $zip");
        
                $zone = '3DS' . $zone;
                
                $rate_chart = 'UPS_US_3day_select';
                
        } elsif ($ship_method eq '2DAY')       {
                $zone = $DB_edirect->selectrow_array("SELECT 2day_air FROM UPS_US_zone
                                                WHERE $zip between zip1 and zip2
                                                OR zip1 = $zip");
                
                $zone = '2DA' . $zone;
                                
                $rate_chart = 'UPS_US_2day_air';
                
        } elsif ($ship_method eq 'NEXTDAY')       {
                $zone = $DB_edirect->selectrow_array("SELECT nextday_air FROM UPS_US_zone
                                                WHERE $zip between zip1 and zip2
                                                OR zip1 = $zip");
                
                $zone = 'NDA' . $zone;
                
                $rate_chart = 'UPS_US_nextday_air';
                
        } 
        
    $ST2_DB = $DB2_edirect->prepare("SELECT qty, weight 
                                FROM products p, cart c
                                WHERE c.session_id = '$session_id'
                                and c.site_id = '$site_id'
                                and c.prod_id = p.prod_id");
    $ST2_DB->execute();   
    while (@results = $ST2_DB->fetchrow_array) {
        my ($qty, $weight) = @results;
        $total_weight += ($qty * $weight);
    
    }
    
    $total_weight = sprintf("%d", $total_weight);   
    $total_weight += 1;
    $ST2_DB->finish();
    
    if ($total_weight > 150) {
        $ST_DB = $DB_edirect->prepare("SELECT $zone FROM $rate_chart
                                        WHERE weight = '150'");
    } else {
        $ST_DB = $DB_edirect->prepare("SELECT $zone FROM $rate_chart
                                        WHERE weight = '$total_weight'");
    }
    
    $ST_DB->execute();
    $ship_rate = $ST_DB->fetchrow_array();
    $ST_DB->finish();

  ## ADD FUEL SURCHAGE TO SHIP RATE  
    $ship_rate += 2;
        
    if ($ship_rate > 0 && $ship_rate < 7) {
        $ship_rate = 7.68;
    } 

    if ($order_total < 25) {
        $ship_rate += 2;
    }
  
    if ($ship_method eq 'GROUND' && $order_total >= 199 && $form{cust_sctry} ne 'ca') { 
        $ship_rate = sprintf("%.2f", 0);
    } elsif ($ship_method eq 'GROUND' && $order_total > 100) {
        $ship_rate -= 4;
    } 
    
    if ($form{cust_sctry} eq 'ca') {
        $ship_rate += 30;
    }

    if ($ship_method ne 'GROUND') {
        $ship_rate += 5;
    }
 
 } elsif ($form{cust_sctry} eq 'ca') {
    $ST2_DB = $DB2_edirect->prepare("SELECT qty, weight 
                                FROM products p, cart c
                                WHERE c.session_id = '$session_id'
                                and c.site_id = '$site_id'
                                and c.prod_id = p.prod_id");
    $ST2_DB->execute();   
    while (@results = $ST2_DB->fetchrow_array) {
        my ($qty, $weight) = @results;
        $total_weight += ($qty * $weight);
    
    }
    
    $total_weight = sprintf("%d", $total_weight);   
    $total_weight += 1;
    $ST2_DB->finish();
    
    $ship_rate = $DB2_edirect->selectrow_array("SELECT rate FROM USPS_CA
                                                WHERE weight = '$total_weight'");
                                                
    $ship_rate += 7;
               
 } else {
    $ship_rate = 10;
 }      
     
    $form{ship_total} = $ship_rate;
  
    return sprintf("%.2f", $ship_rate);
 
}
############################# END SUB CALC_SHIPPING ###########################
###############################################################################

###############################################################################
####################### CLOSE ALL DATABASE CONNECTIONS ########################
sub closeDBConnections() {

  $ST_DB->finish() if ($ST_DB->{Active});
  $ST2_DB->finish() if ($ST2_DB->{Active});    
  
  $DB_edirect->disconnect();

        if ($DB2_edirect) {
                $DB2_edirect->disconnect();    
        }       

}
##################### END CLOSE ALL DATABASE CONNECTIONS SUB ##################
############################################################################### 

#################################################################################
########################## CREATE NAVIGATION NODE TREE ##########################
sub create_node_tree() {
 #   $_[0] = 692011;
    
    my ($cnode_id, @node_tree, @nodes);
    $cnode_id = shift;
           
      
    if (length($cnode_id) == 2) {
        @nodes = $DB_edirect->selectrow_array("SELECT store_id, store_name FROM storefronts
                    WHERE store_id = $cnode_id");
        

    } elsif (length($cnode_id) == 3) {
        @nodes = $DB_edirect->selectrow_array("SELECT s.store_id, store_name, sd.dept_id, dept_name 
                    FROM storefronts s, store_departments sd
                    WHERE s.store_id = sd.store_id
                    and sd.dept_id = $cnode_id");
                   
    } elsif (length($cnode_id) == 4) {
        @nodes = $DB_edirect->selectrow_array("SELECT s.store_id, store_name, sd.dept_id, dept_name, a.aisle_id, aisle_name 
                    FROM storefronts s, store_departments sd, store_aisles a
                    WHERE s.store_id = sd.store_id
                    and sd.dept_id = a.dept_id
                    and a.aisle_id = $cnode_id");
    } elsif (length($cnode_id) == 5) {
        @nodes = $DB_edirect->selectrow_array("SELECT s.store_id, store_name, sd.dept_id, dept_name, a.aisle_id, aisle_name, 
                    sx.section_id, section_name 
                    FROM storefronts s, store_departments sd, store_aisles a, store_sections sx
                    WHERE s.store_id = sd.store_id
                    and sd.dept_id = a.dept_id
                    and a.aisle_id = sx.aisle_id
                    and sx.section_id = $cnode_id");
    } elsif (length($cnode_id) == 6) {
        @nodes = $DB_edirect->selectrow_array("SELECT s.store_id, store_name, sd.dept_id, dept_name, a.aisle_id, aisle_name, 
                    sx.section_id, section_name, sh.shelf_id, shelf_name
                    FROM storefronts s, store_departments sd, store_aisles a, store_sections sx, store_shelves sh
                    WHERE s.store_id = sd.store_id
                    and sd.dept_id = a.dept_id
                    and a.aisle_id = sx.aisle_id
                    and sx.section_id = sh.section_id
                    and sh.shelf_id = $cnode_id");
    }


    for ($i=0, $n=0; $i<length($cnode_id)-1;$i++, $n+=2) {            
        $node_tree[$i] = {node_id=>"$nodes[$n]", node_name=>"$nodes[$n+1]"}; 
    }
    
    
#    print "CATALOG NODES::<br>";   
#    for (my $i=0; $i<@node_tree; $i++) {
#       print qq^ID: $node_tree[$i]->{node_id}<br>NAME: $node_tree[$i]->{node_name}<br>^;
#    }
    
    return \@node_tree;
     

}
######################## END CREATE NAVIGATION NODE TREE ########################
#################################################################################       

###############################################################################
############################# SEND EMAIL SUBROUTINE ###########################
sub email_send() {
    use Net::SMTP;
    
    my ($SENDTO, $SENDFROM, $SUBJECT, $MESSAGE, $SENDCC) = @_;
    
    my $HOST = '127.0.0.1';
    my $PORT = '25';
    
    my $SMTP = Net::SMTP->new( Host => $HOST,
                               Hello => 'mail.usacabinethardware.com',
                               Timeout => 30,
                               Debug => 1);
                               
    $SMTP->mail($SENDFROM);
    $SMTP->to($SENDTO);
    
    if ($SENDCC) {
        $SMTP->cc($SENDCC);
    }
    
    $SMTP->data();
    $SMTP->datasend("To: $SENDTO\n");   
    
    if ($SENDCC) {
        $SMTP->datasend("Cc: $SENDCC\n");
    }
     
    $SMTP->datasend("Subject: $SUBJECT\n\n");
    
    if ($MESSAGE =~ m/^FILE-TO-SEND--/) {
        my ($gar, $FILENAME) = split(/--/, $MESSAGE);
        open(MSGFILE, "$FILENAME") or die "Can't open $FILENAME in sub email_send";
        
        while (<MSGFILE>) {
            $SMTP->datasend("$_");
        }
        
        close(MSGFILE);
    } else {
      $SMTP->datasend("$MESSAGE\n");
    }
    
    $SMTP->dataend();

    $SMTP->quit;
    
}
############################### END  SUB SEND EMAIL ###########################
###############################################################################

################################################################################
######################### GET PRODUCT IMAGE SUBROUTINE #########################
sub get_prod_image() {
    my ($pid, $image_name, $bid, $gid, $image_type, $path);
    $pid = shift();
    $image_type = shift();
    ($bid, $gid) = $DB_edirect->selectrow_array("SELECT brand_id, group_id FROM products
                                          WHERE prod_id = '$pid'");
    $path = "${home_dir}img/${image_type}/${bid}/";

    $pid = 'thmb-' . $pid if ($image_type eq 'thmb');
    $gid = 'thmb-' . $gid if ($image_type eq 'thmb');
                                                  
    if (-e "${path}${pid}\.jpg") {
        $image_name = "${path}${pid}\.jpg";
        $return_image_url = "${img_url}${image_type}/${bid}/${pid}" . '.jpg';
    } elsif (-e "${path}${pid}\.gif") {
        $image_name = "${path}${pid}\.gif";
        $return_image_url = "${img_url}${image_type}/${bid}/${pid}" . '.gif';
    } elsif (-e "${path}${gid}\.jpg") {
        $image_name = "${path}${gid}\.jpg";   
        $return_image_url  = "${img_url}${image_type}/${bid}/${gid}" . '.jpg';   
    } elsif (-e "${path}${gid}\.gif") {
        $image_name ="${path}${gid}\.gif";  
        $return_image_url  = "${img_url}${image_type}/${bid}/${gid}" . '.gif';                  
    } else {
        $image_name = "${home_dir}img/" . 'img-not-avail.gif';
        $return_image_url  = ${img_url} . 'img-not-avail.gif';
    }

    return("$image_name", "$return_image_url");
    
}
############################### END get_prod_image SUB #########################
################################################################################

###############################################################################
######################## MAIL MESSAGE TO mail_store SUBROUTINE ################
sub mail_store() {
        my ($msg, $title, $source) = @_;
        my $entire_message;
        
        open(MAIL, "|$mail") or die "Can't open sendmail in mail_store sub!";
        
        print MAIL "To: $return_mail\n";
        print MAIL "From: $return_mail\n";
        print MAIL "Subject: $title\n\n";
        
        $entire_message = "$msg";
        
        if ($source) {
                $entire_message .= "\nAction was perform by $source.";
        }
        
        print MAIL "$entire_message";
        
        close MAIL;
        
}
###################### MAIL MESSAGE TO mail_store SUBROUTINE ##################
###############################################################################

#################################################################################
############################ PAGE CONTINUATION SUBROUTINE #######################
sub page_continuation() {
    my ($current_page, $total_item_count, $current_index, $previous_page, @low_pages, 
        @hi_pages, $next_page, $total_pages, $first_page_url, $previous_page_url,
        $next_page_url, $last_page_url);
    
    ($total_item_count, $current_index) = @_;
    
   
  ##DETERMINE & PRINT PAGE CONTINUATION NAVIGATION        
    $cont_url = $cgi_url . 'usastore.pl?a=' . $form{a};
        
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

###############################################################################
################################ PAGE FOOTER SUBROUTINE #######################
sub page_footer() {
        print qq^
        
        <tr>            
        <td><img src="${img_url}space.gif" width=500 height=20></td></tr>
        <tr><td class="footNav">
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
Copyright &copy; 2006-2010 usacabinethardware.com by Everything Direct, Inc.<br>
1046 39th Ave W<br>
West Fargo, ND 58078<br>
1.877.281.7905<br>
<a href="mailto:webadmin@usacabinethardware.com">webadmin</a>
<br><br>
</td></tr>
        </table>

</td>

</tr>
</table> 

</body>
</html>
^;
}
############################## END SUB page_footer ############################
###############################################################################

###############################################################################
############################# PAGE HEADER SUBROUTINE ##########################
sub page_header() {
        if (!$ENV{HTTP_COOKIE} && $session_id) {
                print "Set-cookie:sid=$session_id;domain=$ENV{HTTP_HOST}\n";
        }
        print "Content-type: text/html\n\n";
        print qq^<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
                <html><head><title>Shop Cabinet Hardware at USACabinetHardware.com</title>^;
  
  if ($ENV{HTTP_HOST} eq 'secure.usacabinethardware.com') {
        print qq^                
         <link rel=\"Stylesheet\" type=\"text/css\" href=\"${secure_url}main.css\">
         <SCRIPT SRC=\"${secure_url}usa.js\"></SCRIPT>\n^;
  } else {
        print qq^                
         <link rel=\"Stylesheet\" type=\"text/css\" href=\"${base_url}main.css\">
         <SCRIPT SRC=\"${base_url}usa.js\"></SCRIPT>\n ^;
  }

  if ($form{a} eq 'cart_display' || $form{a} eq 'cart_add') {
      print qq^<script language="JavaScript" src="http://www.trustlogo.com/trustlogo/javascript/trustlogo.js"></script>
      <style>
      #specialMessage {
          border: 2px solid #00E600;
          padding: 5px;
          text-align: center;
          font-weight: bold;
          color: #00E600;
          font-size: 11pt;
      }
      #specialMessage p {
          font-size: 9pt;
          margin: 0;
          padding: 0;
           color: #000;
      }
      </style>^;
  }
  
  if ($form{a} eq 'cart_submit') {
       print qq^<SCRIPT language="JavaScript" type="text/javascript">
<!-- Yahoo! Inc.
window.ysm_customData = new Object();
window.ysm_customData.conversion = "transId=,currency=,amount=";
var ysm_accountid  = "1Q19PM6IQLREIGTTKCSMDJ3EEC8";
document.write("<SCR" + "IPT language='JavaScript' type='text/javascript' " 
+ "SRC=//" + "srv1.wa.marketingsolutions.yahoo.com" + "/script/ScriptServlet" + "?aid=" + ysm_accountid 
+ "></SCR" + "IPT>");
// -->
</SCRIPT>^;
  }

        
  if ($form{a} eq 'b' || $form{a} eq 'di') {
        print "</head><body margin-width=0 leftmargin=0 margin-height=0 topmargin=0>";
  } else {
        print "</head><body margin-width=0 leftmargin=0 margin-height=0 topmargin=0>";
  }
  
  print qq^

<table align="center" width="780" border="0" cellpadding="0" cellspacing="0">
<tr>
<td>
<map name="_head">
<area shape="rect" coords="310,39,404,57" href="${cgi_url}usastore.pl?a=cart_display" alt="" >
<area shape="rect" coords="413,40,527,57" href="https://secure.usacabinethardware.com/cgi-bin/usastore.pl?a=checkout" alt="" >
<area shape="rect" coords="539,41,668,55" href="${base_url}customer-care.html" alt="" >
<area shape="rect" coords="681,40,775,56" href="${base_url}contact.html" alt="" >
<area shape="rect" coords="691,12,780,33" href="${base_url}search.html" alt="" >
<area shape="rect" coords="491,11,657,30" href="${base_url}catches-locks.phtml" alt="" >
<area shape="rect" coords="342,11,475,30" href="${base_url}drawer-slides.phtml" alt="" >
<area shape="rect" coords="261,12,330,29" href="${base_url}hinges.phtml" alt="" >
<area shape="rect" coords="98,11,249,29" href="${base_url}knobs-pulls.phtml" alt="" >
<area shape="rect" coords="0,4,82,64" href="${base_url}index.html" alt="" >
</map><img name="head" src="${img_url}head.gif" width="780" height="76" border="0" usemap="#_head" alt="">

</td>
</tr>
^;
        
}
############################# END SUB page_header #############################
###############################################################################

###############################################################################
############################### FORM PARSE SUBROUTINE #########################
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
################################ END SUB parse ################################
###############################################################################

################################################################################
######################## SESSION-ID SUBROUTINE #################################
sub session_id() {

        # FIRST CHECK TO SEE IF USER HAS A CURRENT SESSION 
        # BY CHECKING FOR A SESSION_ID CODED INTO HTML PAGE
        # OR IF USER HAS A COOKIE. IF NONE OF THESE EXIST
        # LOOKUP LAST SESSION IN SESSIONS TABLE AND INCREMENT
        # BY 1 AND CREATE NEW SESSION

    if (!$session_id || $session_id eq '') {
      ##LOCK sessions TABLE FOR THIS SESSION
        $ST_DB = $DB_edirect->do("LOCK TABLES sessions WRITE, orders WRITE");
        
        if ($form{sid} && $form{sid} ne 'get') {
                $session_id = $form{sid};
        } elsif ($ENV{HTTP_COOKIE}) {
                my @cookie = split(/;/, $ENV{HTTP_COOKIE});
                foreach (@cookie) {
                        my ($var, $val) = split(/=/);
                        if ($var eq 'sid') {
                                $session_id = $val;
                                last;
                        }
                }
        } 

        if (!$session_id || $session_id eq '') {
                $session_id = $DB_edirect->selectrow_array("SELECT session_id
                                                        FROM sessions
                                                        WHERE ip_address = '$ENV{REMOTE_ADDR}'");  
        }
              
        if (!$session_id || $session_id eq '') {
                do {
                        $session_id = $DB_edirect->selectrow_array("SELECT NOW() + 0");        
                }  while ($DB_edirect->selectrow_array("SELECT * FROM sessions 
                                                WHERE session_id = '$session_id'"));
                                                                
                $ST_DB = $DB_edirect->do("INSERT INTO sessions 
                                                VALUES ($session_id, '$ENV{REMOTE_ADDR}', NOW())");
        }
        
      ##UNLOCK sessions TABLE FOR THIS SESSION
        $ST_DB = $DB_edirect->do("UNLOCK TABLES");
    }
} 
############################### END SUB session_id #############################
################################################################################

################################################################################
# SUB strip_num TO STRIP UNNECESSARY CHARACTERS AND SPACES FROM A NUMBER STRING
sub strip_num() {
        
        $_[0] =~ s/\s//g;
        $_[0] =~ s/\D//g;
                
        return $_[0];   

}
############################### END SUB strip_num ##############################
################################################################################

################################################################################
############################### SUB track_session ##############################
sub track_session() {
    my ($sid, $next_entry, $current_page);
    
    ($sid, $current_page) = @_;   

    $next_entry = $DB_edirect->selectrow_array("SELECT max(session_entry_num) + 1
                              FROM session_tracking
                              WHERE session_id = '$sid'
                              and site_id = '$site_id'");
                              
    $next_entry = 1 if(!defined($next_entry));
                         
    $ST_DB = $DB_edirect->do("INSERT INTO session_tracking(session_id, site_id,
                                         session_entry_num, session_page)
                               VALUES('$sid',
                                      '$site_id',
                                      '$next_entry',
                                      '$current_page')");
                
    return;   

}
########################### END SUB track_session ##############################
################################################################################

1;

