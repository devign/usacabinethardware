#!/usr/bin/perl 

# DATE: 08/13/06
# AUTH: JW Raugutt
# PROG: usastore.pl
# DESC: usacabinethardware.com total e-commerce application
# Uses edirect shared MYSQL database.

# REVISIONS:

# call in libraries 
use DBI;
use File::Remove qw(remove);
use Image::Info qw(image_info dim);
require qw(usalib.pl);

# call HTML form parsing subroutine
&parse();

# DECLARE GLOBAL VARIABLES
$action = $form{a};
$img_url = '';
#$cgi_url = 'http://www.usacabinethardware.com/cgi-bin/';
$cgi_url = 'http://www.usacabinethardware.com/cgi-bin/';
$secure_cgi = 'https://secure.usacabinethardware.com/cgi-bin/';
$base_url = 'http://www.usacabinethardware.com/';
#$base_url = 'http://www.usacabinethardware.com/';
$secure_url = 'https://secure.usacabinethardware.com/';
$home_dir = '/vhosts/usacabinethardware.com/htdocs/';
$root_dir = '/vhosts/usacabinethardware.com/';
#$home_dir = '/var/www/html/usa/';
$session_id = '';
$mail = '/usr/sbin/sendmail -t';
$site_id = '4';
$return_mail = 'orders@usacabinethardware.com';

%actionCodes = (di => 'cat_detail_item',
        s => 'cat_search',
        b => 'cat_browse');
        
$action = 'cart_checkout' if ($action eq 'checkout');

$form{cnid} = $form{scid} if (exists($form{scid}));
$form{cnid} = $form{cid} if (exists($form{cid})); 
$form{cnid} = $form{did} if (exists($form{did}));
      
# DETERMINE IF WE ARE IN SECURE MODE AND SET IMAGE URL ACCORDINGLY
if ($ENV{HTTP_HOST} eq 'secure.usacabinethardware.com') {
        $img_url = 'https://secure.usacabinethardware.com/img/';
} else {
        $img_url = 'http://www.usacabinethardware.com/img/';
}

############################################################################### 
# -------------------------MAIN LOGIC OF APPLICATION --------------------------
###############################################################################

# OPEN TWO CONNECTIONS TO MYSQL DB SERVER
$DB_edirect = DBI->connect('DBI:mysql:edirect:localhost:', 'edweb', 'gh0rAc', {
        RaiseError=>1,
        PrintError=>1
});
$DB2_edirect = DBI->connect('DBI:mysql:edirect:localhost:', 'edweb', 'gh0rAc', {
        RaiseError=>1,
        PrintError=>1
});

&session_id();

if ($form{a} =~ m/^.{1,2}$/) {
        my $a = $form{a};
        $action = $actionCodes{"$a"};
}

&page_header();

# CALL SUBROUTINE DEPENDENT UPON ACTION FROM HTML PAGE
&$action;

&page_footer();

&closeDBConnections();

exit;


############################################################################### 
# ---------------------------    SUBROUTINES   --------------------------------
###############################################################################

###############################################################################
########################## ADD ITEMS TO CART SUBROUTINE #######################
sub cart_add() {
        
#        &session_id();
        
        my $line_no = 0;
        
        if ($form{recalc} && $form{recalc} eq 'yes') {
                $ST_DB = $DB_edirect->do("DELETE FROM cart
                                    WHERE session_id = '$session_id'
                                        and site_id = $site_id");
        }
        
        $ST_DB2 = $DB_edirect->prepare("SELECT MAX(line_no)
                                    FROM cart
                                    WHERE session_id = '$session_id'
                                        and site_id = $site_id
                                        GROUP BY session_id");
        $ST_DB2->execute();
        my $maxLine = $ST_DB2->fetchrow_array();
        $ST_DB2->finish();
        
        if (!$maxLine) {
                $line_no = 1;
        } else {
                $line_no = $maxLine + 1;
        }

        foreach my $key (sort keys %form) {
                if ($key =~ /_qty/ && $form{$key} ne '' && $form{$key} != 0) {
                
                    &track_session("$session_id", 'CART_ADD');
                                   
                        if ($key !~ /\_GRP1_qty$/) {
                                my ($prod_id, $garbage) = split(/_/, $key);
                                my $qty = $form{$key};
                                $qty =~ s/\D//g;
                                $qty =~ s/\s//g;
                                $ST_DB = $DB_edirect->prepare("SELECT session_id, line_no
                                                        FROM cart 
                                                        WHERE session_id = '$session_id'
                                                        and site_id = $site_id
                                                        and prod_id = '$prod_id'");
                                $ST_DB->execute();
                                my @prodCheck = $ST_DB->fetchrow_array();
                                $ST_DB->finish();
                                if (@prodCheck) {
                                        $ST_DB = $DB_edirect->do("UPDATE cart SET qty = (qty + $qty) 
                                                        WHERE session_id = '$session_id'
                                                        and site_id = $site_id
                                                        and line_no = $prodCheck[1]
                                                        and prod_id = '$prod_id'");
                                } else {
                                        my $vend_id = $DB2_edirect->selectrow_array("SELECT vend_id 
                                                        FROM products
                                                        WHERE prod_id = '$prod_id'");
                                        $ST_DB = $DB_edirect->do("INSERT into cart(session_id, site_id, 
                                                        line_no, qty, prod_id, vend_id)
                                                        VALUES ('$session_id',
                                                        $site_id,
                                                        $line_no,
                                                        $qty,
                                                        '$prod_id',
                                                        $vend_id)");
                                }
                        } else {
                                my ($group_id, $garbage) = split(/_qty$/, $key);
                                my $qty = $form{$key};
                                $qty =~ s/\D//g;
                                $qty =~ s/\s//g;
                                my $prod_id = $form{"${group_id}_pid"};
                                $ST_DB = $DB_edirect->prepare("SELECT session_id, line_no
                                                        FROM cart 
                                                        WHERE session_id = '$session_id'
                                                        and site_id = $site_id
                                                        and prod_id = '$prod_id'");
                                $ST_DB->execute();
                                my @prodCheck = $ST_DB->fetchrow_array();
                                $ST_DB->finish();
                                if (@prodCheck) {
                                        $ST_DB = $DB_edirect->do("UPDATE cart SET qty = (qty + $qty) 
                                                        WHERE session_id = '$session_id'
                                                        and site_id = $site_id
                                                        and prod_id = '$prod_id'");
                                } else {
                                        my $vend_id = $DB2_edirect->selectrow_array("SELECT vend_id 
                                                        FROM products
                                                        WHERE prod_id = '$prod_id'");                           
                                        $ST_DB = $DB_edirect->do("INSERT into cart(session_id, site_id, 
                                                        line_no, qty, prod_id, vend_id)
                                                        VALUES ('$session_id',
                                                        $site_id,
                                                        $line_no,
                                                        $qty,
                                                        '$prod_id',
                                                        $vend_id)");
                                }
                        }
                        $line_no++;
                }
        }

        &cart_display();
                                            
} 
################################# END SUB ADD #################################
###############################################################################

###############################################################################
########################## STORE CHECK OUT SUBROUTINE #########################
sub cart_checkout() {
  
        my $cart_test = $DB_edirect->selectrow_array("SELECT line_no FROM cart 
                                                        WHERE session_id = '$session_id'
                                                        and site_id = '$site_id'");
        
        if (!$cart_test) {
                &cart_empty();
                &page_footer();
                &closeDBConnections();
                exit;
        }
        
        if (exists($form{sa})) {
            my $sa = $form{sa};
            &$sa;
        } else {
            &cscr1();
        }
                
}
############################## END SUB CHECKOUT ###############################
###############################################################################

###############################################################################
############################ CLEAR CART SUB ###################################
sub cart_clear() {
        
        $ST_DB = $DB_edirect->do("LOCK TABLES cart WRITE, sessions WRITE, cart_owner WRITE, cart_save WRITE");
        
        $ST_DB = $DB_edirect->do("DELETE FROM cart WHERE session_id = '$session_id' and site_id = '$site_id'");
        $ST_DB = $DB_edirect->do("DELETE FROM cart_owner WHERE session_id = '$session_id' and site_id = '$site_id'");
        $ST_DB = $DB_edirect->do("DELETE FROM sessions WHERE session_id = '$session_id'");
        $ST_DB = $DB_edirect->do("DELETE FROM cart_save WHERE session_id = '$session_id' and site_id = '$site_id'");
        
        $ST_DB = $DB_edirect->do("UNLOCK TABLES");
        
        if (exists($form{sa}) && $form{sa} ne 'cart_submit') {
                print qq^ <TR><TD style="text-align:center" style="padding-top:20px;padding-bottom:60px">
<a href="http://www.jdoqocy.com/fk117js0ys-FIIPLIJIFHGKNHOLO" target="_blank">
<img src="http://www.tqlkg.com/k8101qmqeki366D96763548B5C9C" alt="Free Super Saver Shipping on $99 or More" border="0"/></a><br><br>
                        <font size=6>Your cart has been cleared!</font></TD></TR> ^;
        } elsif ($form{a} eq 'cart_clear') {
                print qq^ <TR><TD style="text-align:center"  style="padding-top:20px;padding-bottom:60px">
<a href="http://www.jdoqocy.com/fk117js0ys-FIIPLIJIFHGKNHOLO" target="_blank">
<img src="http://www.tqlkg.com/k8101qmqeki366D96763548B5C9C" alt="Free Super Saver Shipping on $99 or More" border="0"/></a><br><br>
                        <font size=6>Your cart has been cleared!</font></TD></TR> ^;
        }

} 
################################# END CLEAR CART SUB ##########################
###############################################################################

###############################################################################
######################### DISPLAY CART SUBROUTINE #############################
sub cart_display() {

        # DECLARE AND INIT LOCAL VARIABLES
        my $sub_total = 0;
        my $display_type;
        
        &session_id();
        
        if (@_) {
                $display_type = $_[0];
        } else {
                $display_type = '';
        }

        # PREPARE SQL FOR EXECUTION
        $ST_DB = $DB_edirect->prepare("SELECT c.qty, c.prod_id, p.detail_descp, p.size1, p.finish, p.price, p.disc_qty, p.disc_amt 
                                            FROM cart c, products p 
                                            WHERE c.session_id = '$session_id'
                                            and c.site_id = '$site_id'
                                            and c.prod_id = p.prod_id");
        # EXECUTE SQL           
        $ST_DB->execute();
        $results = $ST_DB->fetchall_arrayref();
        $ST_DB->finish();
                
        
        if (@$results != 0) {
        # PRINT CART CONTENTS   
            print qq^<TR><TD style="text-align:center" style="padding-top:15px">
                        <table border=0 cellpadding=0 cellspacing=0><tr><td valign=top>
                        <form method=post action=\"${cgi_url}usashipcalc.pl\">
                        <input type=hidden name=cust_sctry value=us>
                        <input type=hidden name=sid value=$session_id>
                       <table border=0 cellpadding=3 cellspacing=0>
                        <tr>
                        <td>    
                                <table border=1 bordercolor=#000000 width=150 cellpadding=5 
                                cellspacing=0 align=left>
                                <tr>
                                <td bgcolor=\"#30507F\" style="text-align:center">
                                <font color=\"#FFFFFF\" size=2> 
                                <b>SHIPPING CALCULATOR</b></font></td></tr>
                                
                                <tr><td class=tiny style="padding-top:15px;padding-bottom:15px"><b>U.S.A. ONLY:</b><br>
                                Enter your zip code and click the 
                                CALCULATE button. Your shipping will be
                                calculated and displayed for you, allowing you to make
                                an informed decision before you begin the checkout 
                                process.<br>
                                </td></tr>
                                <tr><td align="center" class=tiny>Enter Zip Code:
                                <input type=text 
                                name=cust_szip value=\"\" size=5 class=small></td></tr>
                                <tr><td style="text-align:center"><input class=formButton type=submit
                                value=\"CALCULATE\"></td></tr>
                                </table>
                                </form>
                       </td>
                       </tr>
                       <tr>
                       <td>      <table border=1 bordercolor=#000000 width=150 cellpadding=5 
                                cellspacing=0 align=left>
                                <tr>
                                <td bgcolor=\"#30507F\" style="text-align:center">
                                <font color=\"#FFFFFF\" size=2> 
                                <b>SAVE YOUR CART</b></font></td></tr>
                                
                                <tr><td class=small style="padding-top:15px;padding-bottom:15px">
                                Enter your email address to save your cart so 
                                you can come back in 10 minutes or 10 days to
                                order the items in your cart. 
                                                            
                                </td></tr>
                                <tr><td class=small>
                                <form style="margin:0" method="post" action="usastore.pl">
                                <span style="color:firebrick">Enter Your Email Address:</span>
                                <input type="hidden" name="a" value="cart_save">
                                <input type="text" name="cart_owner_email" value="" size="17">
                                <div style="padding:10px;text-align:center">
                                
                                </div>
                                </td>
                                </tr>
                                <tr><td style="padding:10px;text-align:center">
                                <span style="background-image: url(${img_url}floppy-disk.gif); background-position: 10px;" >
                                <input type="submit" class="formButton" value="SAVE">
                                </span>
                                </td>
                                </form>
                                </td></tr>
                                </table>
                         </td>
                         </tr> 

                        </table>
                   </form>
                   </td>  <td valign=top>
                        <table border=0 width=100% cellpadding=2 cellspacing=1>
                                <form method=post action=\"${cgi_url}usastore.pl\">
                                <input type=hidden name=a value=cart_add>
                                <input type=hidden name=recalc value=yes>
                        <TR>
                                <TD colspan=8 class=detail>
                                <font size=\"3\"><b>Your Cart Contents</b></font><br>
                                To change quantities, change the number (or to remove an item
                                , enter <b>0</b>) in the quantity box and click the 
                                <b>\"Recalculate\"</b> button in the lower left.  To completely 
                                remove all of the items from your cart, click the 
                                <b>\"Clear Cart\"</b> link. To continue shopping, click the 
                                <b>\"Continue Shopping\"</b> link. If you 
                                 are ready to checkout, click the <b>\"Checkout\"</b> link.
                                </TD></TR>
                                <TR>
                                <TD colspan=8>
                                <img src=\"${img_url}space.gif\" width=400 height=10>
                                </TD></TR>
                                <TR bgcolor=\"#C5CDEZ\">
                                <TH><font color=\"#000000\" size=2>QTY</font></TH>
                          <!--      <TH style="width:30px"><font color=\"#000000\" size=2>IMAGE</font></TH> -->
                                <TH><font color=\"#000000\" size=2>PROD. ID</font></TH>
                                <TH><font color=\"#000000\" size=2>SIZE</font></TH>
                                <TH><font color=\"#000000\" size=2>DESCP</font></TH>
                                <TH><font color=\"#000000\" size=2>FINISH</font></TH>
                                <TH><font color=\"#000000\" size=2>PRICE</font></TH>
                                <TH><font color=\"#000000\" size=2>TOTAL</font></TH>
                                </TR> ^;
                
                $discount = 0;
                foreach $result (@$results) {
                        ($qty, $prod_id, $descp, $size, $finish, $price, $disc_qty, $disc_amt) = @$result;
                        my @prod_image_info;
                        
                        if (($disc_qty != 0) && ($qty >= $disc_qty)) {
                                $discount += &calcDiscount($qty, $price, $disc_amt);
                        }
                                        
                        $price = sprintf("%.2f", $price);
                        my $prod_total = $qty * $price;
                        $prod_total = sprintf("%.2f", $prod_total);
                        $sub_total += $prod_total;
                        print qq^ <TR>
                                <TD class=tiny>^;
                                
                        if ($form{sa} ne 'cart_summary' && $form{sa} ne 'cart_submit') {
                                print qq^<input style="font-size:10px" type=text name=${prod_id}_qty value=\"$qty\" size=\"2\"> ^;
                        }
                        
           #             @prod_image_info = &get_prod_image("$prod_id", "thmb");
                                
                        print qq^ </TD>
                           <!--     <TD class=small>
                                <a href="${cgi_url}usastore.pl?a=di&pid=${prod_id}">
                                <img border="0" src="$prod_image_info[1]" width="30" height="30"></a>
                                </TD> -->
                                <TD class=small><a href="${cgi_url}usastore.pl?a=di&pid=${prod_id}">
                                ${prod_id}</a></TD><TD class=small>$size</TD>
                                <TD class=small>$descp</TD><TD class=small>$finish</TD>
                                <TD class=small style="text-align:right">\$${price}</TD>
                                <TD class=small style="text-align:right">\$${prod_total}</TD></TR>
                                <TR><TD colspan=8><hr noshade></TD></TR> ^;
                }
                
                $discount += $form{ON_discount} if (exists($form{ON_discount}) && $form{ON_discount} > 0);
                $sub_total = sprintf("%.2f", $sub_total);               

                print qq^<TR><TD colspan=2 class=detail>
                                <input class=formButton type=submit value=\"Recalculate\"></td></form>
                                <TD colspan=2 style="text-align:center" valign=top>
                                <div id="specialMessage">
                                FREE GROUND SHIPPING
                                <p>On orders of \$199 or more!</p>
                                <p style="font-size:7pt;font-weight:normal;margin-top:5px">Continental U.S. Only</p>
                                </div>
                                </TD> 
                                <TD colspan=2 style="text-align:right" class=detail>
                                <b>SUB TOTAL:</b></TD>
                                <TD style="text-align:right" class=detail>\$${sub_total}</TD></TR>^;
               

                
        # PRINT CART SUMMARY LINES      
                
          # QUANTITY DISCOUNT           
                if ($discount != 0 || $form{promo_code}) {
                  # IF PROMO CODE EXISTS, SET PROMO DISCOUNT 
                        if ($form{promo_code}) {
                                $ST_DB = $DB_edirect->prepare("SELECT promo_name, promo_type, promo_amount
                                                                  FROM promotions
                                                                  WHERE promo_id = '$form{promo_code}'");
                                $ST_DB->execute();
                                my @promo_info = $ST_DB->fetchrow_array();
                                $ST_DB->finish();
                        
                                if ($promo_info[1] eq 'P') {
                                        $promo_discount = $sub_total * ($promo_info[2] / 100);
                                } else {
                                        $promo_discount = $promo_info[2];
                                }
                                                                
                                if ($form{promo_code} eq 'HFD13' && $sub_total < 50) {  
                                        $promo_discount = 0;
                                }
                                $discount += $promo_discount;
                        }       
                        
                        $discount = sprintf("%.2f", $discount);
                        $sub_total -= $discount;
                        print qq^<TR><TD colspan=6 style="text-align:right;color:firebrick" class=detail><b>ORDER DISCOUNT:</b></TD>
                                                <TD style="text-align:right;color:firebrick" class=detail> - \$${discount}</TD></TR>^;
                        $form{discount} = $discount;
                }
                
          # SALES TAX FOR MINNESOTA CUSTOMERS
                if ($form{cust_bstate} eq 'ND' && ($form{sa} eq 'cart_summary' || $form{sa} eq 'cart_submit')) {
                        $salesTax = sprintf("%.2f", $sub_total * .06);
                        print qq^ <TR><TD colspan=6 style="text-align:right" class=detail><b>ND SALES TAX:</b></TD>
                                <TD style="text-align:right" class=detail>\$${salesTax}</TD></TR> 
                                <input type=hidden name=salestax value=\"$salesTax\">^;
                        $sub_total += $salesTax;
                        
                }

     # PRINT SHIPPING IF SHIPPING METHOD HAS BEEN SELECTED
                if ($display_type eq 'shipping') {
#                       if ($sub_total > 150 && $form{ord_ship_method} eq 'GROUND') {
#                               $ship_cost = 0;
#                               $form{ship_cost} = 0;
#                       }
                        $sub_total += $form{ship_total};
                        print qq^ <tr><td colspan=6 class=detail style="text-align:right">
                                <b>SHIPPING: <i>($form{ord_ship_method})</i></b></td>
                                        <td style="text-align:right" class=detail>\$$form{ship_total}</td></tr> ^;
                }       
  
                                
                $sub_total = sprintf("%.2f", $sub_total);       

    # 11/21/2006 ADDED 
    # 06/29/2007 REMOVED
    # 10/08/2007 RE-ADDED, DISCOUNT STARTS AT $1000
                my $ON_discount = &calcOrderNowDiscount($sub_total, $session_id, $discount);
                my ($ORDER_TEXT, $LINK);
                
                if ($ON_discount > 0) {
                    $form{discount} += $ON_discount;
                    $ORDER_TEXT = "CLICK HERE TO ORDER ONLINE NOW AND RECEIVE AN ADDITIONAL \$$ON_discount DISCOUNT! >>>"; 
                    $LINK = $secure_cgi . "usastore.pl?a=cart_checkout&sa=cscr2a&sid=${session_id}&ON_discount=$ON_discount";
                } else {
                    $ORDER_TEXT = 'CHECKOUT >>>'; 
                    $LINK = $secure_cgi . "usastore.pl?a=cart_checkout&sid=${session_id}";
                }
                                          
                print qq^ <TR><TD colspan=6 style="text-align:right;font-weight:bold;font-size:11pt">
                                <b>CART TOTAL:</b></TD>
                                <TD style="text-align:right;font-weight:bold;font-size:11pt">\$${sub_total}</TD></TR></form> ^;

                $form{ord_total} = $sub_total;
                                
                print qq^
                        <TR><TD colspan=7><hr noshade></TD></TR>
                        <TR><TD colspan=7 style="text-align:center">
                        <div style="text-align:center;font-size:15pt;padding:10px"><a href=\"${LINK}\">
                        <b>$ORDER_TEXT</b></a></div></TD>
                        </TR>
                        <TR>
                         <td colspan=2 align=left>
                        <!--
BEGIN QUALITYSSL REALTIME SEAL CODE 1.0
Shows the seal graphic from URL http://www.usacabinethardware.com/img/qssl_90.gif
The seal graphic is Not Floating
//-->
<script type="text/javascript">TrustLogo("http://www.usacabinethardware.com/img/qssl_trustlogo.gif", "QLSSL", "none");
</script>               
<noscript><img src="${img_url}img/qsslnojs_90.gif" width="90"></noscript>
                        </td>
                        <TD colspan=2 style="text-align:center" class=detail>
                        <a href=\"${cgi_url}usastore.pl?a=cart_clear&sid=${session_id}\">
                        Clear Cart</a></TD>
                        <TD colspan=2 style="text-align:center" class=detail>
                        <a href=\"javascript:history.back()\">
                        Continue Shopping</a></TD>
                        <td colspan=3 align=right>
<!-- (c) 2006. Authorize.Net is a registered trademark of Lightbridge, Inc. --> <div class="AuthorizeNetSeal"> <script type="text/javascript" language="javascript">var ANS_customer_id="dc497bc7-522f-4f6d-9f64-c02a34627aef";</script> <script type="text/javascript" language="javascript" src="//VERIFY.AUTHORIZE.NET/anetseal/seal.js" ></script> <a href="http://www.authorize.net/" id="AuthorizeNetText" target="_blank">Online Payments</a> </div> 
                        </td>
                        </TR>
</td>
</tr>
</table>
                        <TR><TD colspan=7 style="padding-top:20px">
                        &nbsp;
                        </TD></TR>                      
                        </table>
                        </TD></TR> ^;
                                
        } else {
                &cart_empty();  
        }
} 
############################### END DISPLAY_CART SUB ###########################
################################################################################

################################################################################
############## VIEW CART ON ORDER SUMMARY SUBROUTINE ###########################
sub cart_display_summary() {     
        # DECLARE AND INIT LOCAL VARIABLES
        my $sub_total = 0;
        my $display_type;
        
        &session_id();
        
        if (@_) {
                $display_type = $_[0];
        } else {
                $display_type = '';
        }

        # PREPARE SQL FOR EXECUTION
        $ST_DB = $DB_edirect->prepare("SELECT c.qty, c.prod_id, p.detail_descp, p.size1, p.finish, p.price, p.disc_qty, p.disc_amt 
                                            FROM cart c, products p 
                                            WHERE c.session_id = '$session_id'
                                            and c.site_id = '$site_id'
                                            and c.prod_id = p.prod_id");
        # EXECUTE SQL           
        $ST_DB->execute();
        $results = $ST_DB->fetchall_arrayref();
        $ST_DB->finish();
                
        
        if (@$results != 0) {
        # PRINT CART CONTENTS   
            
                print qq^<table border=0 width=100% cellpadding=2 cellspacing=1>
                                <TR>
                                <TD colspan=7>
                                <img src=\"${img_url}space.gif\" width=400 height=10>
                                </TD></TR>
                                <TR bgcolor=\"#C5CDEZ\">
                                <TH><font color=\"#000000\" size=2>QTY</font></TH>
                                <TH><font color=\"#000000\" size=2>PROD. ID</font></TH>
                                <TH><font color=\"#000000\" size=2>SIZE</font></TH>
                                <TH><font color=\"#000000\" size=2>DESCP</font></TH>
                                <TH><font color=\"#000000\" size=2>FINISH</font></TH>
                                <TH><font color=\"#000000\" size=2>PRICE</font></TH>
                                <TH><font color=\"#000000\" size=2>TOTAL</font></TH>
                                </TR> ^;
                
                $discount = 0;
                foreach $result (@$results) {
                        ($qty, $prod_id, $descp, $size, $finish, $price, $disc_qty, $disc_amt) = @$result;

                        if (($disc_qty != 0) && ($qty >= $disc_qty)) {
                                $discount += &calcDiscount($qty, $price, $disc_amt);
                        }
                                        
                        $price = sprintf("%.2f", $price);
                        my $prod_total = $qty * $price;
                        $prod_total = sprintf("%.2f", $prod_total);
                        $sub_total += $prod_total;
                        print qq^ <TR>
                                <TD class=small>$qty</TD>
                                <TD class=small>${prod_id}</TD><TD class=small>$size</TD>
                                <TD class=small>$descp</TD><TD class=small>$finish</TD>
                                <TD class=small style="text-align:right">\$${price}</TD>
                                <TD class=small style="text-align:right">\$${prod_total}</TD></TR>
                                <TR><TD colspan=7><hr noshade></TD></TR> ^;
                }
                
                $discount += $form{ON_discount} if (exists($form{ON_discount}) && $form{ON_discount} > 0);
                $sub_total = sprintf("%.2f", $sub_total);               
                

                print qq^<TR>
                                <TD colspan=6 style="text-align:right" class=detail>
                                <b>SUB TOTAL:</b></TD>
                                <TD style="text-align:right" class=detail>\$${sub_total}</TD></TR>^;


                
        # PRINT CART SUMMARY LINES      
                
          # QUANTITY DISCOUNT           
                if ($discount != 0 || $form{promo_code}) {
                  # IF PROMO CODE EXISTS, SET PROMO DISCOUNT 
                        if ($form{promo_code}) {
                                $ST_DB = $DB_edirect->prepare("SELECT promo_name, promo_type, promo_amount
                                                                  FROM promotions
                                                                  WHERE promo_id = '$form{promo_code}'");
                                $ST_DB->execute();
                                my @promo_info = $ST_DB->fetchrow_array();
                                $ST_DB->finish();
                        
                                if ($promo_info[1] eq 'P') {
                                        $promo_discount = $sub_total * ($promo_info[2] / 100);
                                } else {
                                        $promo_discount = $promo_info[2];
                                }
                                                                
                                if ($form{promo_code} eq 'HFD13' && $sub_total < 50) {  
                                        $promo_discount = 0;
                                }
                                $discount += $promo_discount;
                        }       
                        
                        $discount = sprintf("%.2f", $discount);
                        $sub_total -= $discount;
                        print qq^<TR><TD colspan=6 style="text-align:right" class=detail><b>ORDER DISCOUNT:</b></TD>
                                                <TD style="text-align:right" class=detail> - \$${discount}</TD></TR>^;
                        $form{discount} = $discount;
                }
                
          # SALES TAX FOR MINNESOTA CUSTOMERS
                if ($form{cust_bstate} eq 'ND' && ($form{sa} eq 'cart_summary' || $form{sa} eq 'cart_submit')) {
                        $salesTax = sprintf("%.2f", $sub_total * .06);
                        print qq^ <TR><TD colspan=6 style="text-align:right" class=detail><b>ND SALES TAX:</b></TD>
                                <TD style="text-align:right" class=detail>\$${salesTax}</TD></TR> 
                                <input type=hidden name=salestax value=\"$salesTax\">^;
                        $sub_total += $salesTax;
                        
                }

                $sub_total += $form{ship_total};
                print qq^ <tr><td colspan=6 class=detail style="text-align:right">
                              <b>SHIPPING: <i>($form{ord_ship_method})</i></b></td>
                                        <td style="text-align:right" class=detail>\$$form{ship_total}</td></tr> ^;
     
                $sub_total = sprintf("%.2f", $sub_total);       

    # 11/21/2006 ADDED 
    # 06/29/2007 REMOVED
    # 10/08/2007 RE-ADDED, DISCOUNT STARTS AT $1000
                my $ON_discount = &calcOrderNowDiscount($sub_total, $session_id, $discount);
                my ($ORDER_TEXT, $LINK);
                
                if ($ON_discount > 0) {
                    $form{discount} += $ON_discount;
                    $ORDER_TEXT = "CLICK HERE TO ORDER ONLINE NOW AND RECEIVE AN ADDITIONAL \$$ON_discount DISCOUNT! >>>"; 
                    $LINK = $secure_cgi . "usastore.pl?a=cart_checkout&sa=cscr2a&sid=${session_id}&ON_discount=$ON_discount";
                } else {
                    $ORDER_TEXT = 'CHECKOUT >>>'; 
                    $LINK = $secure_cgi . "usastore.pl?a=cart_checkout&sid=${session_id}";
                }
                                          
                if ($form{sa} ne 'cart_summary' && $form{a} ne 'cart_submit') {
                        print qq^ <TR><TD colspan=6 style="text-align:right" class=detail>
                                <b>CART TOTAL:</b></TD>
                                <TD style="text-align:right" class=detail>\$${sub_total}</TD></TR></form> ^;
                } else {
                        print qq^ <TR><TD colspan=6 style="text-align:right" class=detail>
                                <b>ORDER TOTAL:</b></TD>
                                <TD style="text-align:right" class=detail>\$${sub_total}</TD></TR> ^;        
                }                       

                $form{ord_total} = $sub_total;
                    
         
                print qq^<TR><TD colspan=7 style="padding-top:20px">
                                &nbsp;
                                </TD></TR>                      
                                </table>
                                </TD></TR> ^;
                                
        } else {
                &cart_empty();  
        }
} 
######################## END cart_display_summary SUB ##########################
################################################################################
   
################################################################################
############################# EMPTY CART SUBROUTINE ############################ 
sub cart_empty() {
        print qq^<TR><TD style="padding-top:40px; padding-bottom:40px" style="text-align:center">
                <table width=600>
                <tr><td style="text-align:center"><font size=4>
                Your cart is currently empty.  To add
                items to your cart, simply indicate the quantity you'd like to add
                and click the \"ADD TO CART \" button.</td></tr>
                <tr><td style="text-align:center;padding:20px">
                If you have previously saved a cart and would like to acces it, please
                enter the email address used and click GET CART.
                <form method="post" action="usastore.pl">
                <input type="hidden" name="a" value="cart_get">
                <strong>EMAIL ADDRESS:</strong> <input class="largeInput" type="text" name="cart_owner_email" value="" size="25">
                <input type="submit" class="formButtonBig" value="GET CART">
                </form>
                </td>
                </tr>
                </table>
        <TD></TR> ^;
}
################################# END EMPTY CART SUB ###########################
################################################################################

################################################################################
########################## CUSTOMER INFO SUBROUTINE ############################
sub cart_info() {       
        
        my $location = $secure_cgi . 'usastore.pl';
        
        print qq^<form name="checkoutForm" method=post action="${secure_cgi}usastore.pl" >
                <input type=hidden name=a value=cart_checkout>
                <input type=hidden name=sa value=cart_summary>  
                <input type=hidden name=sid value=$session_id>
               <input type=hidden name=ON_discount value="$form{ON_discount}">
                <TR>
                        <TD colspan=2 style="text-align:center">
                        <table width=700 cellpadding=5 cellspacing=0 border=0>
                        <tr>
                        <td rowspan=2><H2>CHECK OUT</H2></td><td>
                        <font size=2><b>Registered Customers</b>, 
                        you can enter your username and password (case sensitive) to use 
                        your existing billing and shipping info.  After entering these, 
                        select your <b>shipping method</b>
                        and click the <b>\"Order Summary\"</b> button at the bottom:
                        <br><br>
                        U: 
                        <input type=text name=retcust_uid value=\"\" size=15 maxlength=12> 
                        P: 
                        <input type=password name=retcust_pwd value=\"\" size=15 maxlength=12>
                        </font> 
                        </td></tr>
                        <tr><td><font size=2>
                        <b>Non-registered customers</b>, please enter the following 
                        information.  Please note that all text fields labeled in 
                        <font color="#3333FF">blue</font> are required to be be filled in. The 
                        shipping fields are only required if the "ship to"
                        info is different than the "sold to".</font>
                        </tr> 
                        </table>
                    </TD></TR>
                        <TR><TD colspan=2 style="text-align:center">
                        <table width=700 cellpadding=5 cellspacing=0 border=2 bordercolor=\"#000000\">
                        <tr bgcolor=\"#800000\"><td><b><font color=\"#FFFFFF\">
                        SOLD TO:</font></b></td><td><font color=\"#FFFFFF\">
                        <B>SHIP TO:</b></font>
                        </td></tr>
                        <tr bgcolor=\"#E4BBBB\">
                        <td>
                                <table border=0 cellpadding=2 cellspacing=0 width=100%>
                                <tr>
                                <td colspan=2 class=small>Company Name:<br>
                                <input type=text name=cust_company value=\"\" size=46></font></td>
                                </tr>
                                <tr>
                                <td class=small><font color="#3333FF">First Name:<br>
                                <input type=text name=cust_bfname value=\"\" size=15></font></td>
                                <td class=small><font color="#3333FF">Last Name:<br>
                                <input type=text name=cust_blname value=\"\" size=20></font></td>
                                <tr>
                                <td colspan=2 class=small><font color="#3333FF">Address 1: <i>(cannot deliver to a PO BOX!)</i><br>
                                <input type=text name=cust_badd1 value=\"\" size=46></font></td>
                                </tr>
                                <tr>
                                <td colspan=2 class=small>Address 2:<br>
                                <input type=text name=cust_badd2 value=\"\" size=46></td>
                                </tr>   
                                <tr>
                                <td colspan=2 class=small><font color="#3333FF">City:<br>
                                <input type=text name=cust_bcity value=\"\" size=46></font></td>
                                </tr>
                                <tr>                            
                                <td class=small><font color="#3333FF">State:<br>
                                <select name=cust_bstate>
                                <OPTION  VALUE="XX">CHOOSE ONE
<OPTION  VALUE="AL">Alabama</option>
<OPTION  VALUE="AK">Alaska</option>
<OPTION  VALUE="AZ">Arizona</option>
<OPTION  VALUE="AR">Arkansas</option>
<OPTION  VALUE="CA">California</option>
<OPTION  VALUE="CO">Colorado</option>
<OPTION  VALUE="CT">Connecticut</option>
<OPTION  VALUE="DE">Delaware</option>
<OPTION  VALUE="DC">Washington D.C.</option>
<OPTION  VALUE="FL">Florida</option>
<OPTION  VALUE="GA">Georgia</option>
<OPTION  VALUE="HI">Hawaii</option>
<OPTION  VALUE="ID">Idaho</option>
<OPTION  VALUE="IL">Illinois</option>
<OPTION  VALUE="IN">Indiana</option>
<OPTION  VALUE="IA">Iowa</option>
<OPTION  VALUE="KS">Kansas</option>
<OPTION  VALUE="KY">Kentucky</option>
<OPTION  VALUE="LA">Louisiana</option>
<OPTION  VALUE="ME">Maine</option>
<OPTION  VALUE="MD">Maryland</option>
<OPTION  VALUE="MA">Massachusetts</option>
<OPTION  VALUE="MI">Michigan</option>
<OPTION  VALUE="MN">Minnesota</option>
<OPTION  VALUE="MS">Mississippi</option>
<OPTION  VALUE="MO">Missouri</option>
<OPTION  VALUE="MT">Montana</option>
<OPTION  VALUE="NE">Nebraska</option>
<OPTION  VALUE="NV">Nevada</option>
<OPTION  VALUE="NH">New Hampshire</option>
<OPTION  VALUE="NJ">New Jersey</option>
<OPTION  VALUE="NM">New Mexico</option>
<OPTION  VALUE="NY">New York</option>
<OPTION  VALUE="NC">North Carolina</option>
<OPTION  VALUE="ND">North Dakota</option>
<OPTION  VALUE="OH">Ohio</option>
<OPTION  VALUE="OK">Oklahoma</option>
<OPTION  VALUE="OR">Oregon</option>
<OPTION  VALUE="PA">Pennsylvania</option>
<OPTION  VALUE="PR">Puerto Rico</option>
<OPTION  VALUE="RI">Rhode Island</option>
<OPTION  VALUE="SC">South Carolina</option>
<OPTION  VALUE="SD">South Dakota</option>
<OPTION  VALUE="TN">Tennessee</option>
<OPTION  VALUE="TX">Texas</option>
<OPTION  VALUE="UT">Utah</option>
<OPTION  VALUE="VT">Vermont</option>
<OPTION  VALUE="VA">Virginia</option>
<OPTION  VALUE="WA">Washington</option>
<OPTION  VALUE="WV">West Virginia</option>
<OPTION  VALUE="WI">Wisconsin</option>
<OPTION  VALUE="WY">Wyoming</option>
<OPTION  VALUE="AB">Alberta</option>
<OPTION  VALUE="BC">British Columbia</option>
<OPTION  VALUE="MB">Manitoba</option>
<OPTION  VALUE="NB">New Brunswick</option>
<OPTION  VALUE="NF">Newfoundland</option>
<OPTION  VALUE="NS">Nova Scotia</option>
<OPTION  VALUE="NT">NW Territories &amp; Nunavut</option>
<OPTION  VALUE="ON">Ontario</option>
<OPTION  VALUE="PE">Prince Edward Island</option>
<OPTION  VALUE="QC">Quebec</option>
<OPTION  VALUE="SK">Saskatchewan</option>
<OPTION  VALUE="YT">Yukon</option>
</select></font></td>
                                <td class=small>
                                <font color="#3333FF">Zip Code:<br>
                                <input type=text name=cust_bzip value=\"\" size=10></font></td>
                                </tr>
                                <tr>
                                <td colspan=2 class=small>Country:<br>
                                <select name=cust_bctry onBlur=\"validateState()\">
                                <option value=\"us\">United States</option>
                                </select>
                                </td></tr>
                                <tr>
                                <td colspan="2" class=small>
                                <font color="#3333FF">Phone:<br>
                                <input type=text name=cust_bphone value=\"\" size=46</font></td>
                                </tr>

                                <tr>
                                <td class=small colspan=2><font color="#3333FF">E-mail:<br>
                                <input type=text name=cust_email value=\"\" size=46></font></td>        
                                </tr><tr><td colspan="2" class=small>
                                <b>IF YOU WOULD LIKE TO REGISTER TO EXPEDITE FUTURE ORDERING, 
                                PLEASE SELECT A USERNAME AND PASSWORD</b> 
                                <i>(OPTIONAL)</i></font>
                                </td>
                                </tr>
                                <tr>
                                <td class=small>Username:<br>
                                <input type=text name=cust_userid value=\"\" size=15>
                                </td>
                                <td class=small>Password:<br>
                                <input type=password name=cust_pwd value=\"\" size=15></td>
                                </tr>   
                                <tr>
                                <td class=small colspan=2>Re-Type Password:<br>
                                <input type=password name=cust_pwd2 value=\"\" size=15 onBlur=\"return validatePwd()\"></td>
                                </tr>
                                </table>                                                        
                        </td>
                        <td valign=top>
                                <table border=0 cellpadding=2 cellspacing=0 width=100%>
                                <tr><td colspan=2 class=small>
                                <input type=checkbox name=ship_same value=Y checked>
                                <i>Same as billing</i><br>
                                </td></tr>
                                <tr>
                                <td colspan=2 class=small>Company Name:<br>
                                <input type=text name=cust_scompany value=\"\" size=46 onFocus="this.form.ship_same.checked=0"></td>
                                </tr>
                                <tr><td class=small>
                                <font color="#3333FF">First Name:<br>
                                <input type=text name=cust_sfname value=\"\" size=15 onFocus="this.form.ship_same.checked=0"></font></td>
                                <td class=small><font color="#3333FF">Last Name:<br>
                                <input type=text name=cust_slname value=\"\" size=20 onFocus="this.form.ship_same.checked=0"></font></td>               
                                </tr>
                                <tr>
                                <td class=small colspan=2><font color="#3333FF">Address 1: <i>(cannot deliver to a PO BOX!)</i><br>
                                <input type=text name=cust_sadd1 value=\"\" size=46 onFocus="this.form.ship_same.checked=0"></font></td>                
                                </tr>
                                <tr>
                                <td colspan=2 class=small>Address 2:<br>
                                <input type=text name=cust_sadd2 value=\"\" size=46 onFocus="this.form.ship_same.checked=0"></td>                
                                </tr>   
                                <tr>
                                <td class=small colspan=2><font color="#3333FF">City:<br>
                                <input type=text name=cust_scity value=\"\" size=46 onFocus="this.form.ship_same.checked=0"></font></td>                
                                </tr>   
                                <tr>
                                <td class=small><font color="#3333FF">State:<br>
                                <select name=cust_sstate onFocus="this.form.ship_same.checked=0">
                                <OPTION  VALUE="XX">CHOOSE ONE
<OPTION  VALUE="AL">Alabama</option>
<OPTION  VALUE="AK">Alaska</option>
<OPTION  VALUE="AZ">Arizona</option>
<OPTION  VALUE="AR">Arkansas</option>
<OPTION  VALUE="CA">California</option>
<OPTION  VALUE="CO">Colorado</option>
<OPTION  VALUE="CT">Connecticut</option>
<OPTION  VALUE="DE">Delaware</option>
<OPTION  VALUE="DC">Washington D.C.</option>
<OPTION  VALUE="FL">Florida</option>
<OPTION  VALUE="GA">Georgia</option>
<OPTION  VALUE="HI">Hawaii</option>
<OPTION  VALUE="ID">Idaho</option>
<OPTION  VALUE="IL">Illinois</option>
<OPTION  VALUE="IN">Indiana</option>
<OPTION  VALUE="IA">Iowa</option>
<OPTION  VALUE="KS">Kansas</option>
<OPTION  VALUE="KY">Kentucky</option>
<OPTION  VALUE="LA">Louisiana</option>
<OPTION  VALUE="ME">Maine</option>
<OPTION  VALUE="MD">Maryland</option>
<OPTION  VALUE="MA">Massachusetts</option>
<OPTION  VALUE="MI">Michigan</option>
<OPTION  VALUE="MN">Minnesota</option>
<OPTION  VALUE="MS">Mississippi</option>
<OPTION  VALUE="MO">Missouri</option>
<OPTION  VALUE="MT">Montana</option>
<OPTION  VALUE="NE">Nebraska</option>
<OPTION  VALUE="NV">Nevada</option>
<OPTION  VALUE="NH">New Hampshire</option>
<OPTION  VALUE="NJ">New Jersey</option>
<OPTION  VALUE="NM">New Mexico</option>
<OPTION  VALUE="NY">New York</option>
<OPTION  VALUE="NC">North Carolina</option>
<OPTION  VALUE="ND">North Dakota</option>
<OPTION  VALUE="OH">Ohio</option>
<OPTION  VALUE="OK">Oklahoma</option>
<OPTION  VALUE="OR">Oregon</option>
<OPTION  VALUE="PA">Pennsylvania</option>
<OPTION  VALUE="PR">Puerto Rico</option>
<OPTION  VALUE="RI">Rhode Island</option>
<OPTION  VALUE="SC">South Carolina</option>
<OPTION  VALUE="SD">South Dakota</option>
<OPTION  VALUE="TN">Tennessee</option>
<OPTION  VALUE="TX">Texas</option>
<OPTION  VALUE="UT">Utah</option>
<OPTION  VALUE="VT">Vermont</option>
<OPTION  VALUE="VA">Virginia</option>
<OPTION  VALUE="WA">Washington</option>
<OPTION  VALUE="WV">West Virginia</option>
<OPTION  VALUE="WI">Wisconsin</option>
<OPTION  VALUE="WY">Wyoming</option>
<OPTION  VALUE="AB">Alberta</option>
<OPTION  VALUE="BC">British Columbia</option>
<OPTION  VALUE="MB">Manitoba</option>
<OPTION  VALUE="NB">New Brunswick</option>
<OPTION  VALUE="NF">Newfoundland</option>
<OPTION  VALUE="NS">Nova Scotia</option>
<OPTION  VALUE="NT">NW Territories &amp; Nunavut</option>
<OPTION  VALUE="ON">Ontario</option>
<OPTION  VALUE="PE">Prince Edward Island</option>
<OPTION  VALUE="QC">Quebec</option>
<OPTION  VALUE="SK">Saskatchewan</option>
<OPTION  VALUE="YT">Yukon</option>
</select></font></td>
                                <td class=small>      
                                <font color="#3333FF">Zip Code:<br>
                                <input type=text name=cust_szip value=\"$form{ship_zip}\" size=10></font></td>          
                                </tr>   
                                <tr>
                                <td class=small colspan=2>Country:<br>
                                <select name=cust_sctry>
                                <option value=\"us\">United States</option>
                                </select>
                                </td></tr>
                                </table>                
                        </td></tr>      
                                
                        <tr bgcolor="#800000">
                        <td><font color=\"#FFFFFF\"><b>SHIPPING METHOD:</font></b></td>
                        <td><font color=\"#FFFFFF\"><b>PAYMENT METHOD:</font></b></td>
                        </tr>
                        <tr bgcolor=\"#E4BBBB\">
                        <td valign=top>
                                <table border=0 cellpadding=2 cellspacing=0 width=100%>                         
                                <tr><td>
                                </tr>
                                <tr><td class=small>  
                                GROUND normally takes 3 to 5 business days in transit from
                                the time your order is shipped.  <b>3 DAY SHIPPING NOT AVAILABLE
                                TO ALASKA OR HAWAII.</b> Orders are normally shipped
                                within 24 hours of receipt (unless noted on individual  
                                product page).<br><br></td></tr>
                                <tr><td class=small>
                                <select name=ord_ship_method>^;
                                        
                if (exists($form{ord_ship_method})) {
                        print qq^<option value=\"$form{ord_ship_method}\">$form{ord_ship_method}</option>^;
                }
                
                print qq^
                                <option value=\"GROUND\">GROUND</option>
                                <option value=\"3DAY\">3DAY SHIPPING</option>
                                <option value=\"2DAY\">2ND DAY AIR</option>
                                <option value=\"NEXTDAY\">NEXTDAY AIR</option>      
                                </select>
                                </td>
                                </tr>
                                <tr><td class=small>
                                Order Notes:<br>
                                <textarea name=ord_ship_struct rows=5 cols=30></textarea>
                                </td></tr>
                                </table>
                        </td>
                        <td valign=top>
                                <table border=0 cellpadding=2 cellspacing=0 width=100%>                         
                                <tr><td colspan=3 class=small>
                
                                <select name=ord_pay_method>
                                <option value=\"AMEX\">AMERICAN EXPRESS</option>
                                <option value=\"DISCOVER\">DISCOVER</option>
                                <option value=\"MASTERCARD\">MASTERCARD</option>
                                <option value=\"VISA\">VISA</option>
                                </select></font>
                                </td></tr>
                                <tr><td colspan=3 class=small>
                                <font color="#3333FF">Card Number:<br>
                                <input type=text name=cust_ccnum value=\"\" size=30></font></td></tr>
                                <tr><td colspan=3 class=small>
                                <font color="#3333FF">Name on Card:<br>
                                <input type=text name=cust_ccname value=\"\" size=30></font></td></tr>
                                <tr><td colspan=3 class=small><font color="#3333FF">Card Code:<br>
                    Last 3 digits of number in signature area
                    on back of Visa or Mastercard.  4 digit number printed on
                    front of Amex card.<br>
                                <input type=text name=cust_cccode value=\"\" size=5>
                                </td>
                                </tr>
                                <tr><td class=small><font color="#3333FF">Expiration Date:<br>
                                MO:<select name=cust_ccmo>
                                <option value=00>00</option>
                                <option value=01>01</option>
                                <option value=02>02</option>
                                <option value=03>03</option>
                                <option value=04>04</option>
                                <option value=05>05</option>
                                <option value=06>06</option>
                                <option value=07>07</option>
                                <option value=08>08</option>
                                <option value=09>09</option>
                                <option value=10>10</option>
                                <option value=11>11</option>
                                <option value=12>12</option>
                                </select></font></td>
                                <td class=small valign=bottom><font color="#3333FF">
                                YR:<select name=cust_ccyear>
                                <option value=00>0000</option>
                                <option value=08>2008</option>
                                <option value=09>2009</option>
                                <option value=10>2010</option>
                                <option value=11>2011</option>
                                <option value=12>2012</option>
                                <option value=13>2013</option>
                                <option value=14>2014</option>
                                <option value=15>2015</option>
                                </select></font>
                                </td>
                                </tr>
                        </table>
                        </td></tr>
                        </table>
                </TD></TR>
                        <TR>
                        <TD style="padding-top:20px" colspan=2 align=middle>
                        <br><font size=3 color=\"#3333FF\">
                        <b>When you are done entering your information, press this button 
                        to view a summary of your order and verify that everything is 
                        correct. </b></font><br>
                        <input type=submit value=\"ORDER SUMMARY >>\">
                        </td>
                        </TR>^;
} 
################################## END SUB INFO ###############################
###############################################################################


################################################################################        
##################### CC AUTHORIZATION SUBROUTINE ##############################
sub cc_auth() {
    use LWP::UserAgent;
        
    my $post_url = 'https://secure.authorize.net/gateway/transact.dll';
    my $authParam;
    
    if ($form{ord_pay_method} ne 'AMEX') {    
          $authParam = "x_version=3.1&x_delim_data=TRUE&x_login=everything120304&x_password=m7prQ3a&x_tran_key=TcE9WwQbQoZTYkCf&x_first_name=$form{cust_bfname}&x_last_name=$form{cust_blname}&x_address=$form{cust_badd1}&x_city=$form{cust_bcity}&x_state=$form{cust_bstate}&x_zip=$form{cust_bzip}&x_phone=$form{cust_bphone}&x_email=$form{cust_email}&x_amount=$form{ord_total}&x_card_num=$form{cust_ccnum}&x_exp_date=$form{cust_ccmo}$form{cust_ccyear}&x_card_code=$form{cust_cccode}";
    } else {
          $authParam = "x_version=3.1&x_delim_data=TRUE&x_login=everything120304&x_password=m7prQ3a&x_tran_key=TcE9WwQbQoZTYkCf&x_first_name=$form{cust_bfname}&x_last_name=$form{cust_blname}&x_address=$form{cust_badd1}&x_city=$form{cust_bcity}&x_state=$form{cust_bstate}&x_zip=$form{cust_bzip}&x_phone=$form{cust_bphone}&x_email=$form{cust_email}&x_amount=$form{ord_total}&x_card_num=$form{cust_ccnum}&x_exp_date=$form{cust_ccmo}$form{cust_ccyear}";
    }
    
    $authParam =~ s/\s/+/g;
    
    my $post_hdrs = new HTTP::Headers(Accept=> 'text/plain', User-Agent=> 'eDirectMall/1.0');
    
    my $trans_req = new HTTP::Request(POST, $post_url, $post_hdrs, $authParam);
    
    my $ua = new LWP::UserAgent;
    
    my $trans_resp = $ua->request($trans_req);
    
    my @resp_codes = ();
    if ($trans_resp->is_success) {
        my $trans_resp_str = $trans_resp->content;
        @resp_codes = split(/,/,$trans_resp_str);
        if ($resp_codes[0] == 1 && $resp_codes[40] ne 'N') {
                return $resp_codes[4],$resp_codes[6];
        } else {
                if ($resp_codes[3] <= 11) {
                        &auth_error("$resp_codes[3]");
                } else {
                        print qq^<tr><td style="text-align:center" style="padding:40px">
                                        YOUR TRANSACTION CANNOT BE APPROVED AT THIS TIME</td></tr>^;
                }
        }
                
    } else {
        print qq^<tr><td style="text-align:center" style="padding:40px">AN ERROR OCCURED DURING EXECUTION OF THIS REQUEST</td></tr>^;
        open (MAIL, "|/usr/sbin/sendmail -t");
        print MAIL "To:jon\@raugutt.com\n";
        print MAIL "Subject: CC AUTH METHOD FAILURE\n\n";
        print MAIL $trans_resp->message;
        close MAIL;
    }
    
    # CODE FOR PRINTING TRANSACTION RESPONSE CODES FOR TESTING & DEBUGGING PURPOSES
    #print "TOTAL RESPONSE CODES: " . $#resp_codes - 1 . "<br>";
    #for($i=0;$i<@resp_codes;$i++) {
    #   print "INDEX $i: $resp_codes[$i]<br>"; 
    #}
        
    ############# auth_error SUBROUTINE ##########
    ##############################################
    sub auth_error() {
                &session_id();
                $location = $secure_cgi . 'usastore.pl';                
                print qq^<form method=post action=usastore.pl onSubmit="this.btnOrdSubmit.value='PROCESSING...';this.btnOrdSubmit.disabled=true;return validateCC(this.form,'$location');">
                                <input type=hidden name=a value=cart_checkout>
                                <input type=hidden name=sa value=cart_submit>
                                <input type=hidden name=sid value=$session_id>
                                <TR><TD style="text-align:center"><br>
                                <font color=\"#C50015\">
                                <b>$_[0] . . . PLEASE RE-ENTER</b><br><br>
                                <i>(Enter all credit card info)</i></font><br><br></TD></TR>
                                <TR><TD colspan=2 style="text-align:center">
                                <table width=500 cellpadding=5 cellspacing=0 bgcolor=\"#CCC999\" border=1 bordercolor=000000>
                                <tr><td>
                                        <table width=100% cellpadding=5 border=0>
                                <tr><td><font size=2><b>Card Type:</b><br>
                                <select name=ord_pay_method>
                                        <option value=\"AMEX\">AMERICAN EXPRESS</option>
                                        <option value=\"DISCOVER\">DISCOVER</option>
                                <option value=\"MASTERCARD\">MASTERCARD</option>
                                <option value=\"VISA\">VISA</option>
                                </select>
                                </td>
                                <td class=reqd><b>Expiration Date:</b><br>
                                <b>MO:</b><select name=cust_ccmo>
                                <option value=00>00</option>
                                <option value=01>01</option>
                                <option value=02>02</option>
                                <option value=03>03</option>
                                <option value=04>04</option>
                                <option value=05>05</option>
                                <option value=06>06</option>
                                <option value=07>07</option>
                                <option value=08>08</option>
                                <option value=09>09</option>
                                <option value=10>10</option>
                                <option value=11>11</option>
                                <option value=12>12</option>
                                </select>&nbsp;&nbsp;
                                <b>YR:</b><select name=cust_ccyear>
                                <option value=00>0000</option>
                                <option value=10>2010</option>
                                <option value=11>2011</option>
                                <option value=12>2012</option>
                                <option value=13>2013</option>
                                <option value=14>2014</option>
                                <option value=15>2015</option>
                                <option value=16>2016</option>
                                <option value=17>2017</option>
                                </select></td>
                                </tr>
                                <tr><td class=reqd>
                                <b>Card Number:</b><br>
                                <input type=text name=cust_ccnum value=\"\" size=30></td>
                                <td class=reqd>
                                <b>Card Code:</b><br>
                    <font size=2>Last 3 digits of number in signature area
                    on back of Visa or Mastercard.  4 digit number printed on
                    front of Amex card.</font>
                                <input type=text name=cust_cccode value=\"\" size=5></td>
                                </tr>
                                <tr>
                                <td class=reqd colspan=2>
                                <b>Cardholders Name:</b><br>
                                <input type=text name=cust_ccname value=\"\" size=30></td></tr>
                                
                </table>
                </td>
                </tr>
                </table>
                </TD></TR>^;
                                                
                foreach my $key (sort keys %form) {
                        if ($key =~ m/cust_/ && $key !~ m/cust_cc/) {
                                print "<input type=hidden name=$key value=\"$form{$key}\">\n";
                        }
                }       
                
                print qq^<input type=hidden name=ord_ship_method value=\"$form{ord_ship_method}\">
                        <input type=hidden name=ord_ship_struct value=\"$form{ord_ship_struct}\">\n
                        <input type=hidden name=ord_total value=\"$form{ord_total}\">
                        <input type=hidden name=salestax value=\"$form{salestax}\">
                        <input type=hidden name=discount value=\"$form{discount}\">
                        <input type=hidden name=discount value=\"$form{ON_discount}\">
                        <input type=hidden name=handling value=\"$form{handling}\">
                        <input type=hidden name=ship_total value=\"$form{ship_total}\">^;
                
                print qq^<TR><TD colspan=2 style="text-align:center" style="padding-top:15px">
                                <input class=frmButton name="btnOrdSubmit" type=submit value=\"RESUBMIT CARD\"></form>
                                </TD></TR>^;

                
        }    
    ############ END SUB auth_error ###################
        ###################################################

}
#################### END CC AUTHORIZATION SUBROUTINE ##########################
###############################################################################
        
###############################################################################
################# CHECKOUT SCREEN 1: ONLINE OR FAX/MAIL #######################
sub cscr1() {   

    &track_session("$session_id", 'CHECKOUT');
            
        my $location = $secure_cgi . 'usastore.pl';
        print qq^ <TR><TD><h2 class=top>CHECKOUT</h2></TD></TR>
                <TR>
                <td style="text-align:center">
                <table width=780 bgcolor=#C5CDEZ bordercolor=black cellpadding=5 cellspacing=0 border=1>
                <tr>
                <td>
                        <table border=0 width=100% cellpadding=5 cellspacing=0>
                        <tr>
                        <td colspan=2 style="padding-bottom:30px"><h2>How would you like to pay for your order?</h2>
                        </td>
                        </tr>
                        <tr>
                        <td style="text-align:center" width=50% bgcolor="#E1A39F">
                <form name="checkoutForm" method=post action="${secure_cgi}usastore.pl">
                <input type=hidden name=a value=cart_checkout>
                <input type=hidden name=sa value=cscr2a> 
                <input type=hidden name=sid value=$session_id>
                <input type=hidden name=ON_discount value="$form{ON_discount}">
                        <input type=submit name=btnSecure value="SECURE ONLINE" class=formButton>
                        </td>
                        </form>
                        <form name="checkoutForm" method=post action="${secure_cgi}usamailorder.pl" >
                <input type=hidden name=st value=1>
                <input type=hidden name=sid value=$session_id>
                <input type=hidden name=ON_discount value="$form{ON_discount}">
                        <td style="text-align:center" bgcolor="#888F9F"><input type=submit value="FAX or MAIL" class=formButton></td>
                        </form>
                        </tr>
                        <tr>
                        <td class=detail>Enter your billing
                                & shipping information and pay <b>securely</b>
                                        online with a major credit card
                                        through Authorize.Net secure payment processing.<br>
                                        </td>
                        
                        <td class=detail valign="top">Enter your billing & shipping
                                   information, select a 
                                   shipping method then generate 
                                   a printable order form to
                                   fax or mail to us.</td></tr></table>
                </td>
                </tr>
                </table>
           </td>
           </tr>     
 <tr>
<td valign="top" align="center"><h2 class="top">STORE POLICIES</h2>
        <table border="1" bordercolor="#000000" cellpadding="5" cellspacing="0" width="780">
        <tr>
        <td width="50%" valign="top" bgcolor="#C5CDE2">
        <a name="privacy"></a>
        <div class="sectionHead">
        Privacy & Security</div>
        </td>
        <td width="50%" valign="top" bgcolor="#C5CDE2">
        <a name="returns"></a>
        <div class="sectionHead">
        Returns</div>
        </td>
        </tr>
        <tr>
        <td class="small" valign="top">
        <b><u>DATA PRIVACY</u></b><br>
        The data we collect during the order process is only used by us internally to process your order and maintain correspondence with you regarding that order.  The only entity that any of your data is shared with is Authorize.Net., however, that is only for the processing of your credit card.  Your personal data is never sold, rented or shared with any other third party.<br><br>
        <b><u>DATA SECURITY</u></b><br>
Ordering from our site is just as (or more) secure as ordering over the telephone or through the mail.  We use the latest in 128 bit SSL data encryption technology to secure the connection between your web browser and our state-of-the-art order processing system.  The secure connection continues from our system to Authorize.Net for credit card processing.  Every connection, every step of the way is secured.  Additionally, our system is continously monitered for possible security holes as new vulnerabilities arise, giving us the advantage of staying one-step ahead of possible intruders by maintaining tight system security. <br><br>
    <b><u>COOKIES</u></b><br> 
        Cookies are harmless little data files
    that are used to "remember" users when they return to a site.  As is the 
    case with most shopping sites, this site
    uses a cookie to keep track of your session id and shopping cart.  
    However, once
    you close your web browser, the cookie is deleted, nothing is stored on
    your computer.  If you have your browser set to deny cookies, you still
    may be able to order as our system also uses the IP address to save 
    your cart information (this only works if you are not being fed from a              
    proxy/cache server, such as <b>AOL</b> uses, in which case you 
    <b>must</b> allow the cookie from our site to be able to proceed with an 
    order).<br><br>
        
<!--
BEGIN QUALITYSSL REALTIME SEAL CODE 1.0
Shows the seal graphic from URL http://www.usacabinethardware.com/img/qssl_90.gif
The seal graphic is Not Floating
//-->
<script type="text/javascript">TrustLogo("https://secure.usacabinethardware.com/img/qssl_70.gif", "QLSSL", "none");
</script>               
<noscript><img src="img/qsslnojs_90.gif" width="90"></noscript> 


        
        </td>
        <td class="small" valign="top">
 	    	<a name="RET"></a>
        	<div class="colHead">RETURNS</div>
            You may return items within 30 days from shipping date.  All merchandise
			returned must be in original un-opened packaging to receive credit. Please open your
			package and verify your order when you receive it. Unless otherwise noted 
    		below, non-defective returned merchandise is subject to a 15% restocking 
    		fee.<br><br>
        
        The following brands have these restocking fees:
			<ul>
			<li><b>Buck Snort Lodge Products</b> - 25% restocking fee</li>
      		<li><b>Emenee Hardware</b> - 25% restocking fee</b></li>
			<li><b>Premier Hardware</b> - 25% restocking fee</b></li>
			</ul>
			
			Please follow the
            procedures below for your return type.<br><br>
            NOTE: Please allow up to 4 weeks for your return to be fully processed and credit issued.<br><br>
            <b>DEFECTIVE MERCHANDISE</b><br>
            1) <a href="returns.html">Submit a request</a> for an RMA (return merchandise authorization).<br>
            2) An RMA number will be issued for your return (you will receive an
            email from us with the RMA# and the instructions for returning the item(s)).
            <br>
            3) Ship the item back, once received and verified, a replacement will be 
            shipped to you or a refund will be given to you. (Refund amount will equal
            the price of the product minus any discounts given, shipping is non-refundable).<br><br>
            <b>NON-DEFECTIVE MERCHANDISE</b><br>
            1) <a href="returns.html">Submit a request</a> for an RMA (return merchandise authorization).<br>
            2) An RMA number will be issued for your return (you will receive an
            email from us with the RMA# and the instructions for returning the item(s)).
            <br>
            3) Ship the item back, once received and verified as being in resaleable condition, 
    		a refund will be given to you. (Refund amount will equal
            the price of the product minus any discounts given minus the restocking fee if applicable,
    		 shipping is non-refundable).<br><br>
            NOTE: Please allow up to 4 weeks for your return to be fully processed and credit issued.<br><br>
    
			<b>ANY MERCHANDISE RETURNED WITHOUT AN RMA# OR RETURNED TO THE WRONG LOCATION
    		WILL BE SUBJECT TO A 50% RESTOCKING FEE - ANY SHIPPING CHARGES INCURRED BY US
    		TO RETURN THE MERCHANDISE TO THE CORRECT WAREHOUSE WILL ALSO BE DEDUCTED FROM
    		YOUR CREDIT<br><br><br>
        			
            <b>ALL SALES ARE FINAL AFTER 30 DAYS. ABSOLUTELY NO CREDIT CAN BE GIVEN AFTER 30 DAYS FROM SHIPMENT DATE.</b>
            <br><br><br>
             ALL ORDER SHORTAGES MUST BE REPORTED WITHIN 48 HOURS OF DELIVERY</b>
        </td>
        </tr>
<!-- BEGIN ROW 2 -->    
        <tr>
        <td width="50%" valign="top" bgcolor="#C5CDE2">
        <div class="sectionHead">
        <a name="shipping"></a>Shipping & Handling
        </td>
        <td width="50%" valign="top" bgcolor="#C5CDE2">
        <div class="sectionHead">
        <a name="samples"></a>Samples
        </td>
        </tr>
        <tr>
        <td class="small" valign="top">
        <u><b>PRODUCT AVAILABILITY</b></u><br>
        Most of the products on our site are in stock and ready to ship the same day 
        if your order is placed before 2:00pm Central Time.  Those items that are
        thinly stocked or not stocked at all, are identified on their respective
        item detail page.<br><br>

		A \$3 small order
        processing fee is added to the shipping on orders less than \$25.00.  We must
        charge this fee to offset some of the charges incurred from our fulfillment
        distributors. 
        <br><br>
                
        <u><b>SHIPPING WITHIN 48 CONTINENTAL U.S.A.</b></u><br>
        For orders shipped within the continental United States, your shipping cost 
        is calculated from shipping rate charts, using the total weight of your 
        order and the shipping method you have chosen. You may choose from  
        Ground, 3Day Ground, 2nd Day AIr or Nextday Air and your order will be
        shipped either by UPS or FedEx via the method you specify. <!--You can also have 
        the shipping calculated before you enter the order placement process by 
        entering your zip code into the
        <b>Shipping Calculator</b> located on the <b>Show Cart</b> screen.--><br><br>
        
        <u><b>SHIPPING OUTSIDE 48 CONTINENTAL U.S.A.</b></u><br>
        We can also ship to Hawaii, Alaska and Canada (sorry, we currently do not offer any
        other international shipping).  You may select from either 2ND Day Air or Next Day
    Air service for Hawaii and Alaska.  All Canadian orders are shipped via USPS.<br><br>
<!--    
        <ol>
        <li>Add all items you wish to order to your shopping cart.</li>
        <li>Once you have all the items in your cart, click the 
        <a href="https://secure.usacabinethardware.com/cgi-bin/usaorderq.pl?st=1">click here</a> to request a 
        quote.</li>
        <li>Fill out all the required information and submit the form to us.</li>
        <li>We will calculate a shipping cost for you and send you an email.</li>
        <li>If you want to proceed with the order from there, click the link 
        provided to you in the email which will take you to a secure checkout page
        on our site.  Follow the rest of the instructions on the screens to place
        your order.</li>
        </ol> 
-->
        
        </td>
        <td class="small" valign="top">
        We do not offer free samples, discounted samples, free shipping on samples 
        or any other special treatment of sample orders.  Samples are still products 
        that cost money to purchase and ship.  We simply cannot meet our goal of 
        extending the lowest possible prices to all of our customers while sending 
        out samples in any other way than like a regular order. Our sample program 
        is the most simple, logical and economical for both of us.<br><br>
        You can order as many sample pieces as you'd like, we won't tell you 
        how many you can order.  If
        you want to return any sample pieces you will need to follow the return
        procedure above.

        </td>
        </tr>
<!-- BEGIN ROW 3 -->    
        <tr>
        <td width="50%" valign="top" bgcolor="#C5CDE2">
        <div class="sectionHead">
        Image Disclaimer
        </td>
        <td width="50%" valign="top" bgcolor="#C5CDE2">
        <div class="sectionHead">
        <a name="warranty"></a>Warranty
        </td>
        </tr>
        <tr>
        <td class="small" valign="top">
Due to the variances in computer monitors and the various settings to brightness and contrast that users may adjust their monitors to, we cannot guarantee with any certainty that the color represented in a product image on your monitor is exactly as it appears in the physical world. This mainly applies to the decorative cabinet hardware, as these come in several different finishes. If you will be ordering a large quantity of an item and it is imperative that the finish/color is exactly like the image on the site, please order a sample to examine ahead of time. 

        </td>
        <td class="small" valign="top">
All goods sold are the products of the manufacturer, we make no other warranties, expressed or implied, including implied warranties of merchantability and fitness for a particular purpose. USACabinetHardware.com's liability under any claim arising from the sale of goods is limited to the price of the goods on which such liability is based. 

        </td>
        </tr>
        </table>
</td>
</tr>^;
                        
} 
######################### END CHECKOUT SCREEN 1 ###############################
###############################################################################

###############################################################################
########################### CHECKOUT SCREEN 2a: LOGIN #########################
sub cscr2a() {

    &track_session("$session_id", 'CHECKOUT->LOGIN');
    
print qq^ <TR><TD>
                <h2 class=top>CHECKOUT->LOGIN</h2></TD>
                </TR>
                <TR>
                
               <TD colspan=2 style="text-align:center">

                <table border=1 bgcolor=#C5CDEZ bordercolor=black cellspacing=0 cellpadding=0 width=660>
                <tr>
                <td>
                        <table border=0 cellspacing=0 cellpadding=5> 
                        <tr>
                        <td width=30%>
                                <div style="background-color: #FFFFFF; padding: 5px;font-size: 9pt;">
                                <b>INSTRUCTIONS:</b><br>
                                If you are a returning customer who 
                        has registered with a userid and password, please enter, then click 
                        the <b>LOGIN NOW</b> button.<br><br> If you are a new customer or otherwise 
                        don't have a userid and password, click the <b>NOT REGISTERED</b>
                        button.
                                </div>
                        </td>
                        <td>
                        <td class=detail>
                        <form name="checkoutForm" method=post action="${secure_cgi}usastore.pl" >
                        <input type=hidden name=registered value=1>
                        <input type=hidden name=a value=cart_checkout>
                        <input type=hidden name=sa value=cscr2> 
                        <input type=hidden name=sid value=$session_id>
                        <input type=hidden name=ON_discount value="$form{ON_discount}">
                        <b>USERID:</b><br>
                        <input type="text" name="retcust_uid" size="30"><br>
                        <b>PASSWORD:</b><br>
                        <input type="password" name="retcust_pwd" size="30"><br>
                        <!-- <b>DISCOUNT CODE:</b> <i>(if applicable)</i><br>
                        <input type="text" name="promo_code" size="30"><br> -->
                        <input type=submit value="LOGIN NOW" class=formButton><br>
                        </form>
                        </td>
                        
                        <td style="text-align:center">
                        <form name="checkoutForm2" method=post action="${secure_cgi}usastore.pl" >
                        <input type=hidden name=registered value=0>
                        <input type=hidden name=a value=cart_checkout>
                        <input type=hidden name=sa value=cscr2> 
                        <input type=hidden name=sid value=$session_id>
                        <input type=hidden name=ON_discount value="$form{ON_discount}">
                        <input type=submit value="NOT REGISTERED" class="formButton formButtonBig">
                        </form>
                        </td>
                        </tr>
                        </table>
</td>
</tr>
</table>^;
}

###############################################################################
############################## CHECKOUT SCREEN 2 ##############################
sub cscr2() {

    &track_session("$session_id", 'CHECKOUT->CUSTOMER INFORMATION');
    
        my $location = $secure_cgi . 'usastore.pl';
        if ($form{registered} == 1) {
           if ($form{retcust_uid} ne '' && $form{retcust_pwd} ne '') {
                        @results= $DB_edirect->selectrow_array("SELECT cust_id, cust_company, 
                                        cust_fname, cust_lname, cust_add1, cust_add2, cust_city, 
                                        cust_state, cust_zip, cust_country,
                                        cust_email, cust_phone
                                        FROM customers
                                        where STRCMP(cust_userid, '$form{retcust_uid}') = 0
                                        and STRCMP(cust_pwd, '$form{retcust_pwd}') = 0");
                        } else {
                                @results = ();
                        }                       
                
                if ($results[0] eq '') {
                        &cscr2a_error('invalid');
                        &page_footer();
                        &closeDBConnections();
                        exit;
                } else {
                        $form{cust_id} = $results[0];
                        $form{cust_company} = $results[1];
                        $form{cust_bfname} = $results[2];
                        $form{cust_blname} = $results[3];
                        $form{cust_badd1} = $results[4];
                        $form{cust_badd2} = $results[5];
                        $form{cust_bcity} = $results[6];
                        $form{cust_bstate} = $results[7];
                        $form{cust_bzip} = $results[8];
                        $form{cust_bctry} = $results[9];
                        $form{cust_email} = $results[10];
                        $form{cust_bphone} = $results[11];
                }
          
print qq^<TR><TD><h2 class=top>CHECKOUT->CUSTOMER INFORMATION</h2></TD></TR>
                 <TR><form name="billForm" method=post action="${secure_cgi}usastore.pl" onSubmit="return validateBilling(this, '$location')">
                <input type=hidden name=a value=cart_checkout>
                <input type=hidden name=sa value=cscr3> 
                <input type=hidden name=sid value=$session_id>
                <input type=hidden name=ON_discount value="$form{ON_discount}">
                        <td style="text-align:center">
                <table width=660 bgcolor=#C5CDEZ bordercolor=black cellpadding=2 cellspacing=0 border=1>
                <tr>
            <td>
                        <table bgcolor=#FFFFFF border=0 cellpadding=5 cellspacing=0>
                        <tr><td class=detail>
                        <b>INSTRUCTIONS:</b><br>
                        Please verify your billing information and make any changes 
                        necessary.  If you want your order shipped to this same location, 
                        leave the checkmark in the checkbox next to <b>"SHIP TO THIS SAME
                        ADDRESS"</b> at the bottom. Otherwise uncheck it and you will be 
                        given another form to enter
                        the shipping information into.<br><br>
                        When everything on this page is
                        complete and accurate, click the <b>CONTINUE >></b> button to go to the
                        next screen.
                        </td>
                        </tr>
                        </table>
                </td>
                <td>
                        <table width=480 border=0 cellspacing=0 cellpadding=2>
<tr>
<td colspan=3 class=detailB>Company:<br>
<input type=text name=cust_company value="$form{cust_company}" size=30></td>
</tr>
<tr>
<td class=reqd>First Name:<br>
<input type=text name=cust_bfname value="$form{cust_bfname}" size=30></td>
<td class=reqd colspan=2>Last Name:<br>
<input type=text name=cust_blname  value="$form{cust_blname}" size=30></td>
</tr>
<tr>
<td class=reqd>Address 1: <i>(cannot ship to a PO BOX!)</i><br>
<input type=text name=cust_badd1 value="$form{cust_badd1}" size=30></td>
<td class=detailB colspan=2>Address 2:<br>
<input type=text name=cust_badd2 value="$form{cust_badd2}" size=30></td>
</tr>
<tr>
<td class=reqd>City:<br>
<input type=text name=cust_bcity value="$form{cust_bcity}" size=30></td>
<td class=reqd>State:<br>
<select  name=cust_bstate>
<OPTION value="$form{cust_bstate}">$form{cust_bstate}</option>
<OPTION  VALUE="AL">Alabama</option>
<OPTION  VALUE="AK">Alaska</option>
<OPTION  VALUE="AZ">Arizona</option>
<OPTION  VALUE="AR">Arkansas</option>
<OPTION  VALUE="CA">California</option>
<OPTION  VALUE="CO">Colorado</option>
<OPTION  VALUE="CT">Connecticut</option>
<OPTION  VALUE="DE">Delaware</option>
<OPTION  VALUE="DC">Washington D.C.</option>
<OPTION  VALUE="FL">Florida</option>
<OPTION  VALUE="GA">Georgia</option>
<OPTION  VALUE="HI">Hawaii</option>
<OPTION  VALUE="ID">Idaho</option>
<OPTION  VALUE="IL">Illinois</option>
<OPTION  VALUE="IN">Indiana</option>
<OPTION  VALUE="IA">Iowa</option>
<OPTION  VALUE="KS">Kansas</option>
<OPTION  VALUE="KY">Kentucky</option>
<OPTION  VALUE="LA">Louisiana</option>
<OPTION  VALUE="ME">Maine</option>
<OPTION  VALUE="MD">Maryland</option>
<OPTION  VALUE="MA">Massachusetts</option>
<OPTION  VALUE="MI">Michigan</option>
<OPTION  VALUE="MN">Minnesota</option>
<OPTION  VALUE="MS">Mississippi</option>
<OPTION  VALUE="MO">Missouri</option>
<OPTION  VALUE="MT">Montana</option>
<OPTION  VALUE="NE">Nebraska</option>
<OPTION  VALUE="NV">Nevada</option>
<OPTION  VALUE="NH">New Hampshire</option>
<OPTION  VALUE="NJ">New Jersey</option>
<OPTION  VALUE="NM">New Mexico</option>
<OPTION  VALUE="NY">New York</option>
<OPTION  VALUE="NC">North Carolina</option>
<OPTION  VALUE="ND">North Dakota</option>
<OPTION  VALUE="OH">Ohio</option>
<OPTION  VALUE="OK">Oklahoma</option>
<OPTION  VALUE="OR">Oregon</option>
<OPTION  VALUE="PA">Pennsylvania</option>
<OPTION  VALUE="RI">Rhode Island</option>
<OPTION  VALUE="SC">South Carolina</option>
<OPTION  VALUE="SD">South Dakota</option>
<OPTION  VALUE="TN">Tennessee</option>
<OPTION  VALUE="TX">Texas</option>
<OPTION  VALUE="UT">Utah</option>
<OPTION  VALUE="VT">Vermont</option>
<OPTION  VALUE="VA">Virginia</option>
<OPTION  VALUE="WA">Washington</option>
<OPTION  VALUE="WV">West Virginia</option>
<OPTION  VALUE="WI">Wisconsin</option>
<OPTION  VALUE="WY">Wyoming</option>
<OPTION  VALUE="AB">Alberta</option>
<OPTION  VALUE="BC">British Columbia</option>
<OPTION  VALUE="MB">Manitoba</option>
<OPTION  VALUE="NB">New Brunswick</option>
<OPTION  VALUE="NF">Newfoundland</option>
<OPTION  VALUE="NS">Nova Scotia</option>
<OPTION  VALUE="NT">NW Territories &amp; Nunavut</option>
<OPTION  VALUE="ON">Ontario</option>
<OPTION  VALUE="PE">Prince Edward Island</option>
<OPTION  VALUE="QC">Quebec</option>
<OPTION  VALUE="SK">Saskatchewan</option>
<OPTION  VALUE="YT">Yukon</option>
</select></td>
<td class=reqd>Zip Code:<br>
<input type=text name=cust_bzip value=$form{cust_bzip} size=10></td>
</tr>
<input type=hidden name=cust_bctry value=$form{cust_bctry}></td>

<tr>
<td class=reqd>Phone:<br>
<input type=text name=cust_bphone value="$form{cust_bphone}" size=30></td>
<td class=reqd colspan=2>E-mail:<br>
<input type=text name=cust_email value="$form{cust_email}" size=20 onBlur="validateEmail(this.form, this.value)"></td>
</tr>

                   </table>
</td>
</tr>
</table>
</TD></TR>
<TR><TD style="text-align:center" style="padding-top:15px" class=detailB>
<input type=checkbox name=ship_same value=Y checked>SHIP TO THIS SAME ADDRESS<br><br>
<input type=submit name=continue value="CONTINUE >>" class="formButton formButtonBig"></TD></TR><input type=hidden name=registered value=$form{registered}>
        <input type=hidden name=cust_id value="$form{cust_id}">
        <input type=hidden name=promo_code value="$form{promo_code}">
                </form> ^;

        } else {

print qq^<TR><TD><h2 class=top>CHECKOUT->CUSTOMER INFORMATION</h2></TD></TR>
                 <TR><form name="billForm2" method=post action="${secure_cgi}usastore.pl" onSubmit="return validateBilling(this, '$location')">
                <input type=hidden name=a value=cart_checkout>
                <input type=hidden name=sa value=cscr3> 
                <input type=hidden name=sid value=$session_id>
                <input type=hidden name=ON_discount value="$form{ON_discount}">
                <td style="text-align:center">
                <table width=760 bgcolor=#C5CDEZ bordercolor=black cellpadding=2 cellspacing=0 border=1>
                <tr>
                <td width="25%">
                        <table bgcolor=#FFFFFF border=0 cellpadding=5 cellspacing=0>
                        <tr><td class=detail>
                        <b>INSTRUCTIONS:</b><br>
                        Fill out the form completely. All fields labeled in 
                        <font class=reqd>red</font> are 
                        required fields.  If you want your order shipped to the same
                        address, leave the checkmark in the checkbox next to 
                        <b>"SHIP TO THIS SAME ADDRESS"</b>. Otherwise uncheck it and you will be
                        given another form to fill out the shipping information.<br><br>
                        If you would like to register with a username and password, 
                        complete the bottom three fields (NOTE: these are not required
                        unless you want to register, <a href=${base_url}care-faq.html#10>click
                        here</a> to find out what a registered customer is.
                        </td>
                        </tr>
                        </table>
                </td>
                <td style="padding-left:20px">
                        <table width=480 border=0 cellspacing=0 cellpadding=5>
<tr>
<td colspan=3 class=detailB>Company:<br>
<input type=text name=cust_company size=30></td>
</tr>
<tr>
<td class=reqd>First Name:<br>
<input type=text name=cust_bfname  size=30></td>
<td class=reqd colspan=2>Last Name:<br>
<input type=text name=cust_blname  size=30></td>
</tr>
<tr>
<td class=reqd>Address 1: <i>(cannot ship to a PO BOX!)</i><br>
<input type=text name=cust_badd1 size=30></td>
<td class=detailB colspan=2>Address 2:<br>
<input type=text name=cust_badd2  size=30></td>
</tr>
<tr>
<td class=reqd>City:<br>
<input type=text name=cust_bcity  size=30></td>
<td class=reqd>State:<br>
<select  name=cust_bstate>
<OPTION value="XX">CHOOSE STATE</option>
<OPTION  VALUE="AL">Alabama</option>
<OPTION  VALUE="AK">Alaska</option>
<OPTION  VALUE="AZ">Arizona</option>
<OPTION  VALUE="AR">Arkansas</option>
<OPTION  VALUE="CA">California</option>
<OPTION  VALUE="CO">Colorado</option>
<OPTION  VALUE="CT">Connecticut</option>
<OPTION  VALUE="DE">Delaware</option>
<OPTION  VALUE="DC">Washington D.C.</option>
<OPTION  VALUE="FL">Florida</option>
<OPTION  VALUE="GA">Georgia</option>
<OPTION  VALUE="HI">Hawaii</option>
<OPTION  VALUE="ID">Idaho</option>
<OPTION  VALUE="IL">Illinois</option>
<OPTION  VALUE="IN">Indiana</option>
<OPTION  VALUE="IA">Iowa</option>
<OPTION  VALUE="KS">Kansas</option>
<OPTION  VALUE="KY">Kentucky</option>
<OPTION  VALUE="LA">Louisiana</option>
<OPTION  VALUE="ME">Maine</option>
<OPTION  VALUE="MD">Maryland</option>
<OPTION  VALUE="MA">Massachusetts</option>
<OPTION  VALUE="MI">Michigan</option>
<OPTION  VALUE="MN">Minnesota</option>
<OPTION  VALUE="MS">Mississippi</option>
<OPTION  VALUE="MO">Missouri</option>
<OPTION  VALUE="MT">Montana</option>
<OPTION  VALUE="NE">Nebraska</option>
<OPTION  VALUE="NV">Nevada</option>
<OPTION  VALUE="NH">New Hampshire</option>
<OPTION  VALUE="NJ">New Jersey</option>
<OPTION  VALUE="NM">New Mexico</option>
<OPTION  VALUE="NY">New York</option>
<OPTION  VALUE="NC">North Carolina</option>
<OPTION  VALUE="ND">North Dakota</option>
<OPTION  VALUE="OH">Ohio</option>
<OPTION  VALUE="OK">Oklahoma</option>
<OPTION  VALUE="OR">Oregon</option>
<OPTION  VALUE="PA">Pennsylvania</option>
<OPTION  VALUE="RI">Rhode Island</option>
<OPTION  VALUE="SC">South Carolina</option>
<OPTION  VALUE="SD">South Dakota</option>
<OPTION  VALUE="TN">Tennessee</option>
<OPTION  VALUE="TX">Texas</option>
<OPTION  VALUE="UT">Utah</option>
<OPTION  VALUE="VT">Vermont</option>
<OPTION  VALUE="VA">Virginia</option>
<OPTION  VALUE="WA">Washington</option>
<OPTION  VALUE="WV">West Virginia</option>
<OPTION  VALUE="WI">Wisconsin</option>
<OPTION  VALUE="WY">Wyoming</option>
<OPTION  VALUE="AB">Alberta</option>
<OPTION  VALUE="BC">British Columbia</option>
<OPTION  VALUE="MB">Manitoba</option>
<OPTION  VALUE="NB">New Brunswick</option>
<OPTION  VALUE="NF">Newfoundland</option>
<OPTION  VALUE="NS">Nova Scotia</option>
<OPTION  VALUE="NT">NW Territories &amp; Nunavut</option>
<OPTION  VALUE="ON">Ontario</option>
<OPTION  VALUE="PE">Prince Edward Island</option>
<OPTION  VALUE="QC">Quebec</option>
<OPTION  VALUE="SK">Saskatchewan</option>
<OPTION  VALUE="YT">Yukon</option>
</select>
</td>
</tr>

<tr>
<td class=reqd>Country:<br>
<select name=cust_bctry>
<option value="us">UNITED STATES</option>
<option value="ca">CANADA</option>
</select>
</td>
<td class=reqd>Zip/Postal Code:<br>
<input type=text name=cust_bzip  size=15></td>
</tr>
<tr>
<td class=reqd>Daytime Phone:<br>
<input type=text name=cust_bphone  size=30></td>
<td class=reqd colspan=2>E-mail:<br>
<input type=text name=cust_email size=30 onBlur="validateEmail(this, this.value)"></td>
</tr>
        <tr><td colspan=3>
                <table border=0 cellpadding=2 cellspacing=0 width=100%>
                <tr><td colspan=3><hr></hr></td></tr>
                <tr><td colspan=3 class="detailB" style="text-align:center"><h3>OPTIONAL</h3></td></tr>
                <tr><td class=detailB>USERNAME:</td>
                <td class=detailB>PASSWORD:</td>
                <td class=detailB>RE-ENTER PASSWORD:</td></tr>
                <tr><td><input type=text name=cust_uid size=20></td>
                <td><input type=password name=cust_pwd size=20></td>
                <td><input type=password name=cust_pwd2 size=20 onBlur="validatePwd(this.form)"></td></tr>
                </table>
        </td>
        </tr>
        </table>

</td>
</tr>
</table>
</TD></TR>
<TR><TD style="text-align:center" style="padding-top:15px" class=detailB>
<input type=checkbox name=ship_same value=Y checked>SHIP TO THIS SAME ADDRESS<br><br>
<input type=submit name=continue value="CONTINUE >>" class="formButton formButtonBig"></TD></TR><input type=hidden name=registered value=$form{registered}>
                </form> ^;
           }
}
################################## END SUB INFO ###############################
###############################################################################

###############################################################################
###################### USER/PASS ERROR MESSAGE SUBROUTINE #####################
sub cscr2a_error() {
        my $this_error = shift @_;
        
        if ($this_error eq 'invalid') {
                &track_session("$session_id", 'CHECKOUT->LOGIN-{ERROR:INVALID}');
                            
                print qq^<tr><td colspan=2 style="text-align:center"><br><br>
                                <table border=0 width=400>
                                <tr><td style="text-align:center"><font size=4 color=\"#BF4451\">
                                THE USERNAME AND PASSWORD YOU ENTERED
                                DOES NOT MATCH ANY USERNAME PASSWORD COMBINATIONS IN OUR SYSTEM.  PLEASE
                                <a href="javascript:history.back()">CLICK HERE</a> TO RE-ENTER.
                                </td></tr></table></td></tr>^;
        } else {
                &track_session("$session_id", 'CHECKOUT->LOGIN-{ERROR:DUPUSER}');
                        
                print qq^<tr><td colspan=2 style="text-align:center"><br><br>
                                <table border=0 width=400>
                                <tr><td style="text-align:center"><font size=4 color=\"#BF4451\">
                                THE USERNAME YOU HAVE CHOSEN IS ALREADY
                                IN USE BY ANOTHER USER ON THE SYSTEM.  PLEASE
                                <a href="javascript:history.back()">CLICK HERE</a> TO CHOSE ANOTHER ONE.
                                </td></tr></table></td></tr>^;
        }
}
########################## END SUB user_pass_error ############################
###############################################################################

###############################################################################
###################### CHECKOUT SCREEN 3: SHIPPING INFO #######################
sub cscr3(){

    &track_session("$session_id", 'CHECKOUT->SHIPPING INFORMATION');
    
        if ($form{ship_same} eq 'Y') {
                $form{cust_scompany} = $form{cust_company};
                $form{cust_sfname} = $form{cust_bfname};
                $form{cust_slname} = $form{cust_blname};
            $form{cust_sadd1} = $form{cust_badd1};
                $form{cust_sadd2} = $form{cust_badd2};
                $form{cust_scity} = $form{cust_bcity};
                $form{cust_sstate} = $form{cust_bstate};
                $form{cust_szip} = $form{cust_bzip};
                $form{cust_sctry} = $form{cust_bctry};
                &cscr4();

        } else {

print qq^<TR><TD><h2 class=top>CHECKOUT->SHIPPING INFORMATION</h2></TD></TR>
                 <TR><form name="checkoutForm" method=post action="${secure_cgi}usastore.pl" onSubmit="return validateShipping(this, '$location')">
                <input type=hidden name=a value=cart_checkout>
                <input type=hidden name=sa value=cscr4> 
                <input type=hidden name=sid value=$session_id>
                <input type=hidden name=ON_discount value="$form{ON_discount}">
                        <td style="text-align:center">
                <table width=760 bgcolor=#C5CDEZ bordercolor=black cellpadding=2 cellspacing=0 border=1>
                <tr>
            <td width="25%">
                        <table bgcolor=#FFFFFF border=0 cellpadding=5 cellspacing=0>
                        <tr><td class=detail>
                        <b>INSTRUCTIONS:</b><br>
                        Fill out the form completely.  All fields labeled in 
                        <font class=reqd>red</font> are 
                        required fields.<br><br>
                        When you have completed the form, verified your
                        information for accuracy and are ready to proceed, click the
                        <b>CONTINUE >></b> button.
                        </td>
                        </tr>
                        </table>
                </td>
                <td>
                        <table width=520 border=0 cellspacing=0 cellpadding=5>
<tr>
<td colspan=3 class=detailB>Company:<br>
<input type=text name=cust_scompany size=30></td>
</tr>
<tr>
<td class=reqd>First Name:<br>
<input type=text name=cust_sfname  size=30></td>
<td class=reqd colspan=2>Last Name:<br>
<input type=text name=cust_slname  size=30></td>
</tr>
<tr>
<td class=reqd>Address 1: <i>(cannot ship to a PO BOX!)</i><br>
<input type=text name=cust_sadd1 size=30></td>
<td class=detailB colspan=2>Address 2:<br>
<input type=text name=cust_sadd2  size=30></td>
</tr>
<tr>
<td class=reqd>City:<br>
<input type=text name=cust_scity  size=30></td>
<td class=reqd>State:<br>
<select  name=cust_sstate>
<OPTION value="XX">CHOOSE STATE</option>
<OPTION  VALUE="AL">Alabama</option>
<OPTION  VALUE="AK">Alaska</option>
<OPTION  VALUE="AZ">Arizona</option>
<OPTION  VALUE="AR">Arkansas</option>
<OPTION  VALUE="CA">California</option>
<OPTION  VALUE="CO">Colorado</option>
<OPTION  VALUE="CT">Connecticut</option>
<OPTION  VALUE="DE">Delaware</option>
<OPTION  VALUE="DC">Washington D.C.</option>
<OPTION  VALUE="FL">Florida</option>
<OPTION  VALUE="GA">Georgia</option>
<OPTION  VALUE="HI">Hawaii</option>
<OPTION  VALUE="ID">Idaho</option>
<OPTION  VALUE="IL">Illinois</option>
<OPTION  VALUE="IN">Indiana</option>
<OPTION  VALUE="IA">Iowa</option>
<OPTION  VALUE="KS">Kansas</option>
<OPTION  VALUE="KY">Kentucky</option>
<OPTION  VALUE="LA">Louisiana</option>
<OPTION  VALUE="ME">Maine</option>
<OPTION  VALUE="MD">Maryland</option>
<OPTION  VALUE="MA">Massachusetts</option>
<OPTION  VALUE="MI">Michigan</option>
<OPTION  VALUE="MN">Minnesota</option>
<OPTION  VALUE="MS">Mississippi</option>
<OPTION  VALUE="MO">Missouri</option>
<OPTION  VALUE="MT">Montana</option>
<OPTION  VALUE="NE">Nebraska</option>
<OPTION  VALUE="NV">Nevada</option>
<OPTION  VALUE="NH">New Hampshire</option>
<OPTION  VALUE="NJ">New Jersey</option>
<OPTION  VALUE="NM">New Mexico</option>
<OPTION  VALUE="NY">New York</option>
<OPTION  VALUE="NC">North Carolina</option>
<OPTION  VALUE="ND">North Dakota</option>
<OPTION  VALUE="OH">Ohio</option>
<OPTION  VALUE="OK">Oklahoma</option>
<OPTION  VALUE="OR">Oregon</option>
<OPTION  VALUE="PA">Pennsylvania</option>
<OPTION  VALUE="RI">Rhode Island</option>
<OPTION  VALUE="SC">South Carolina</option>
<OPTION  VALUE="SD">South Dakota</option>
<OPTION  VALUE="TN">Tennessee</option>
<OPTION  VALUE="TX">Texas</option>
<OPTION  VALUE="UT">Utah</option>
<OPTION  VALUE="VT">Vermont</option>
<OPTION  VALUE="VA">Virginia</option>
<OPTION  VALUE="WA">Washington</option>
<OPTION  VALUE="WV">West Virginia</option>
<OPTION  VALUE="WI">Wisconsin</option>
<OPTION  VALUE="WY">Wyoming</option>
<OPTION  VALUE="AB">Alberta</option>
<OPTION  VALUE="BC">British Columbia</option>
<OPTION  VALUE="MB">Manitoba</option>
<OPTION  VALUE="NB">New Brunswick</option>
<OPTION  VALUE="NF">Newfoundland</option>
<OPTION  VALUE="NS">Nova Scotia</option>
<OPTION  VALUE="NT">NW Territories &amp; Nunavut</option>
<OPTION  VALUE="ON">Ontario</option>
<OPTION  VALUE="PE">Prince Edward Island</option>
<OPTION  VALUE="QC">Quebec</option>
<OPTION  VALUE="SK">Saskatchewan</option>
<OPTION  VALUE="YT">Yukon</option>
</select>
</td>
</tr>

<tr>
<td class=reqd>Country:<br>
<select name=cust_sctry>
<option value="us">UNITED STATES</option>
<option value="ca">CANADA</option>
</select>
</td>
<td class=reqd>Zip/Postal Code:<br>
<input type=text name=cust_szip  size=15></td>
</tr>

</table>
</td>
</tr>
</table>
</TD></TR>
<TR><TD style="text-align:center" style="padding-top:15px">

<input type=submit name=continue value="CONTINUE >>" class="formButton formButtonBig"></TD></TR> ^;
                foreach my $key (sort keys %form) {
                        if ($key =~ m/^cust_/) {
                                print qq^<input type=hidden name="$key" value="$form{$key}">^;
                        }
                }
                print qq^<input type=hidden name=registered value=$form{registered}>
                <input type=hidden name=promo_code value=$form{promo_code}>
                </form>^;
        }
}
###############################################################################
##############################endscsr4#########################################
sub cscr4() {

    &track_session("$session_id", 'CHECKOUT->SHIPPING AND PAYMENT METHOD');
    
        my ($ground, $threeday, $twoday, $nextday);
        
        $ground = &calc_shipping('GROUND');
    
        if ($form{cust_sstate} ne 'AK' && $form{cust_sstate} ne 'HI') {     
                $threeday = &calc_shipping('3DAY');
        }

        $twoday = &calc_shipping('2DAY');
        $nextday = &calc_shipping('NEXTDAY');
                        
        print qq^<TR><TD><h2 class=top>CHECKOUT->SHIPPING AND PAYMENT METHOD</h2>
                </TD></TR>
                <TR><form name="checkoutForm" method=post action="${secure_cgi}usastore.pl" onSubmit="return validatePayment(this)">
                <input type=hidden name=a value=cart_checkout>
                <input type=hidden name=sa value=cart_summary>  
                <input type=hidden name=sid value=$session_id>
               <input type=hidden name=ON_discount value="$form{ON_discount}">
                        <td colspan=2 style="text-align:center;padding-left:35px">
                <table width=720 bgcolor=#C5CDEZ bordercolor=black cellpadding=2 cellspacing=0 border=1>
                <tr>
            <td width=20%>
                        <table bgcolor=#FFFFFF cellpadding=5 cellspacing=0>
                        <tr><td class=detail>
                        <b>INSTRUCTIONS:</b><br>^;
                        
        if ($form{registered} == 1) {
                print qq^Select how you would like your order shipped to you and enter
                        any order comments or shipping instructions.<br><br>
                        If you would like to
                        use the same credit card that you have previously used, check the
                        box next to <b>USE PREVIOUS CREDIT CARD</b>, otherwise leave it unchecked
                        and enter your credit card information.<br><br>
                        When you have completed
                        all the necessary steps, click the <b>CONTINUE >></b> button to proceed
                        to the ORDER SUMMARY page^;
        } else {
                print qq^Select how you would like your order shipped to you and enter
                        any order comments or shipping instructions.<br><br>
                        Next, enter your 
                        credit card information.  When you have completed
                        all the necessary steps, click the <b>CONTINUE >></b> button to proceed
                        to the ORDER SUMMARY page^;             
        }

        
        print qq^</td></tr>
                 </table>
                 </td>
                 <td>
                        <table width=575 border=1 cellspacing=0 cellpadding=5> 
                        <tr><td class=detailB width=50% valign=top>
                        SELECT SHIPPING METHOD:<br><br>
                                <select name=ord_ship_method>^;
                                
        if ($form{cust_sctry} eq 'ca') {   
             print qq^<OPTION  VALUE="USPS">USPS - \$$ground</option>^;  
        } else {
             print qq^<OPTION  VALUE="GROUND">GROUND - \$$ground</option>^;
        }
                
        if ($form{cust_sstate} ne 'AK' && $form{cust_sstate} ne 'HI' && $form{cust_sctry} ne 'ca') {
            print qq^<OPTION  VALUE="3DAY">3 Day Select - \$$threeday </option>^;
        }
    
        if ($form{cust_sctry} ne 'ca') {
            print qq^<OPTION  VALUE="2DAY">2ND DAY AIR - \$$twoday</option>
                      <OPTION  VALUE="NEXTDAY">NEXTDAY AIR - \$$nextday</option>^;
        }
        
        print qq^</select><div style="padding-top:30px">
                                ORDER/SHIPPING NOTES:<br>
                                <textarea name=ord_ship_struct rows=5 cols=30></textarea>
                                </div>
                                </td>
                                <td class=detailB valign=top>^;
       
       
        if ($form{registered} == 1) {
                print qq^<input type=checkbox name=same_cc value="1"> USE PREVIOUS CREDIT CARD<br>
                                <hr></hr><br>OR USE THIS CARD:<br>^;
        } else {
                print qq^SELECT CREDIT CARD:<br>^;
        }
        
        print qq^<select name=ord_pay_method>
                                <option value=AMEX>American Express</option>
                                <option value=DISCOVER>Discover</option>
                                <option value=MASTERCARD>Mastercard</option>
                                <option value=VISA>Visa<br></option>
                                </select><br><br>
                                CARD #:<br>
                                <input type=text name=cust_ccnum size=25><br><br>
                                CARD CODE:<br>
                                <font size=1>(last 3 digits of number printed in
                                signature area on the back of Visa and Mastercard, 
                                4 digit number printed on right front on Amex)</font><br>
                                <input type=text name=cust_cccode size=10><br><br>
                                CARDHOLDER'S NAME:<br>
                                <input type=text name=cust_ccname size=25><br><br>
                                EXPIRATION DATE:<br>
                                MO: <select name=cust_ccmo>
                                <option value=00>00</option>
                                <option value=01>01</option>
                                <option value=02>02</option>
                                <option value=03>03</option>
                                <option value=04>04</option>
                                <option value=05>05</option>
                                <option value=06>06</option>
                                <option value=07>07</option>
                                <option value=08>08</option>
                                <option value=09>09</option>
                                <option value=10>10</option>
                                <option value=11>11</option>
                                <option value=12>12</option>
                                </select>
                                
                                YR: <select name=cust_ccyear>
                                <option value=00>0000</option>
                                <option value=10>2010</option>
                                <option value=11>2011</option>
                                <option value=12>2012</option>
                                <option value=13>2013</option>
                                <option value=14>2014</option>
                                <option value=15>2015</option>
                                <option value=16>2016</option>
                                <option value=17>2017</option>
                                </select></font><br></td></tr>
                                        </table>
                                </td>
                                </tr>
                                </table>

</TD></TR>
<TR><TD style="text-align:center;padding-top:15px"><input type=submit value="CONTINUE >>" class="formButton formButtonBig">
        </TD></TR>^;
                foreach my $key (sort keys %form) {
                        if ($key =~ m/^cust_/) {
                                print qq^<input type=hidden name="$key" value="$form{$key}">^;
                        }
                }
                print qq^
                <input type=hidden name=registered value=$form{registered}>
                <input type=hidden name=promo_code value=$form{promo_code}>
                </form>^;
        
                
}
############################## END CHECKOUT SCREEN 4 ##########################
###############################################################################

###############################################################################
############################ GET CART SUBROUTINE ############################ 
sub cart_get() {
    $session_id = $DB_edirect->selectrow_array("SELECT session_id FROM cart_owner
                            WHERE site_id = $site_id
                            and cart_owner_email = '$form{cart_owner_email}'");
                            
    my $cart_check = $DB_edirect->selectrow_array("SELECT count(*) FROM cart WHERE session_id = '$session_id' and site_id = $site_id");
    
    if ($cart_check ==   0) {                          
        $ST_DB = $DB_edirect->prepare("SELECT line_no, qty, prod_id FROM cart_save 
                                       WHERE session_id = '$session_id'
                                       and site_id = $site_id");
        $ST_DB->execute();
        
        while (my @cart_contents = $ST_DB->fetchrow_array()) {
            $ST2_DB = $DB2_edirect->do("INSERT INTO cart(session_id, site_id, line_no, prod_id, qty)
                                        VALUES('$session_id', $site_id, $cart_contents[0], '$cart_contents[2]', '$cart_contents[1]')");
        }
        
        $ST_DB->finish();                            
    }
    
    &cart_display();
    return;
}
################################# END GET CART SUB ##########################
###############################################################################

###############################################################################
############################ SAVE CART SUBROUTINE ############################ 
sub cart_save() {
    my ($email_subject, $email_message);
    $email_subject = 'Your Saved Cart at USACabinetHardware.com';
    $email_message = "Thank you for shopping at USACabinetHardware.com.  These are the items you\nrecently added to your cart and saved for later:\n\n";

#DELETE ANY EXISTING DATA IN cart_owner AND cart_save
    $ST_DB = $DB_edirect->do("DELETE FROM cart_owner
                              WHERE cart_owner_email = '$form{cart_owner_email}'
                              and session_id = '$session_id'
                              and site_id = $site_id");

    $ST_DB = $DB_edirect->do("DELETE FROM cart_save
                              WHERE session_id = '$session_id'
                              and site_id = $site_id");
                              
#INSERT CART OWNER INFORMATION INTO cart_owner                                                                                      
    $ST_DB = $DB_edirect->do("INSERT INTO cart_owner(cart_owner_email, cart_date, session_id, site_id)
                              VALUES('$form{cart_owner_email}', NOW(), '$session_id', $site_id)");
                              
    $ST_DB = $DB_edirect->prepare("SELECT line_no, qty, prod_id FROM cart 
                                   WHERE session_id = '$session_id'
                                   and site_id = $site_id");
    $ST_DB->execute();
    
    while (my @cart_contents = $ST_DB->fetchrow_array()) {
        $email_message .= $cart_contents[2] . " \tqty: " . $cart_contents[1] . "\n\n";
        $ST2_DB = $DB2_edirect->do("INSERT INTO cart_save(session_id, site_id, line_no, prod_id, qty)
                                    VALUES('$session_id', $site_id, $cart_contents[0], '$cart_contents[2]', '$cart_contents[1]')");
    }
    
    $ST_DB->finish();
    
    $email_message .= "To access your saved cart, please click the following link:\n\n         http://www.usacabinethardware.com/cgi-bin/usastore.pl?a=cart_get&cart_owner_email=$form{cart_owner_email}\n\n";
                       
    $email_message .= "If you have any questions, please email us at sales\@usacabinethardware.com or call us at 1-877-281-7905.\n\nThank you,\nUSACabinetHardware.com";
    
    &email_send("$form{cart_owner_email}", "$return_mail", "$email_subject", "$email_message", "$return_mail");
                                                                                           
    print qq^<TR><TD><div class="locationNav"><a href="${base_url}index.html">HOME</a> >> 
                  <a href="${cgi_url}usastore.pl?a=cart_display">CART</a> >> SAVE</div>
                  
                  <div id="cartSaveSuccess">
                  <h2>Your cart contents have been saved.</h2>
                  
                  <h3>These items will be saved for you for 30 days.</h3>
                  </div></TD></TR>^;
    

}
################################# END SAVE CART SUB ##########################
###############################################################################

###############################################################################
############################## ORDER SUMMARY SUB ##############################
sub cart_summary() {


            
        if ($form{cust_uid}) {
            $ST_DB = $DB_edirect->prepare("SELECT cust_userid FROM customers
                                            WHERE STRCMP(cust_userid, '$form{cust_userid}') = 0");
            $ST_DB->execute();
            if (my $uid = $ST_DB->fetchrow_array()) {
                    &user_pass_error('duplicate');
                    &page_footer();
                    &closeDBConnections();
                    exit;
            }
        }
        
        $form{cust_company} = uc $form{cust_company} if ($form{cust_company});
        $form{cust_bfname} = uc $form{cust_bfname};
        $form{cust_blname} = uc $form{cust_blname};
        $form{cust_badd1} = uc $form{cust_badd1};
        $form{cust_badd2} = uc $form{cust_badd2} if ($form{cust_badd2});
        $form{cust_bcity} = uc $form{cust_bcity};
            
        if ($form{ship_same}) {
            $form{cust_scompany} = uc $form{cust_company} if ($form{cust_company});
            $form{cust_sfname} = uc $form{cust_bfname};
            $form{cust_slname} = uc $form{cust_blname};
            $form{cust_sadd1} = uc $form{cust_badd1};
            if ($form{cust_badd2}) {
                    $form{cust_sadd2} = uc $form{cust_badd2};
            }
            $form{cust_scity} = uc $form{cust_bcity};
            $form{cust_sstate} = $form{cust_bstate};
            $form{cust_szip} = $form{cust_bzip};
            $form{cust_sctry} = $form{cust_bctry};
        } else {
            $form{cust_scompany} = uc $form{cust_scompany} if ($form{cust_scompany});
            $form{cust_sfname} = uc $form{cust_sfname};     
            $form{cust_slname} = uc $form{cust_slname};
            $form{cust_sadd1} = uc $form{cust_sadd1};
            if ($form{cust_sadd2}) {
                    $form{cust_sadd2} = uc $form{cust_sadd2};
            }
            $form{cust_scity} = uc $form{cust_scity};
        }
        
        if (exists($form{same_cc}) && $form{same_cc} == 1) {
            my $old_inv_no = $DB_edirect->selectrow_array("SELECT min(inv_no) FROM orders WHERE cust_id = $form{cust_id}");
            
            ($form{cust_ccnum}, $form{cust_ccexp}) = 
                    $DB_edirect->selectrow_array("SELECT DECODE(cust_ccnum, '3f6bjPT7'), cust_ccexp FROM cc_trans_log WHERE inv_no = $old_inv_no}");
        }
        
 
        if (!$form{cust_ccexp}) {
                $form{cust_ccexp} =  "$form{cust_ccmo}" . "$form{cust_ccyear}";
        } else {
                $form{cust_ccmo} = substr $form{cust_ccexp}, 0, 2;
                $form{cust_ccyear} = substr $form{cust_ccexp}, -2, 2;
        }
        
        $form{cust_ccname} = uc $form{cust_ccname} if ($form{cust_ccname});
                
        if (!$form{ship_total}) {
            $form{ship_total} = &calc_shipping("$form{ord_ship_method}");
        }
        
# REMOVED 12/3/05 TO SEE IF THIS IS CAUSING LACK OF ORDERS                
#        print qq^<form onSubmit="return validateAgreement(this)"> 
#                <input type=hidden name=a value=cart_submit>    
#                <input type=hidden name=sid value=$session_id>  
#                ^;
        
        print qq^<form method="post" action="usastore.pl"> 
                <input type=hidden name=a value=cart_submit>    
                <input type=hidden name=sid value=$session_id>^;
                
        $form{cust_ccnum} =~ s/\s//g;   
        $form{cust_ccnum} =~ s/-//g;    
        my $temp_ccnum = substr $form{cust_ccnum}, -4;
        $temp_ccnum = "*" x 12 . $temp_ccnum;


    &track_session("$session_id", 'CHECKOUT->ORDER SUMMARY');
    
            
  #PRINT CUSTOMER INFO
        print qq^ <TR><TD><H2 class=top>CHECKOUT->ORDER SUMMARY</H2></TD></TR>
                        
                        <TR><TD style="text-align:center">
                        <table width=720 cellpadding=5 cellspacing=0 border=1 bordercolor=\"#000000\">
                        <tr>
                        <td width=20% class=detailB><font color="#C50015">
                        IMPORTANT:<br>
                        Your order is not complete until you submit this page.</font>
                        </td>
                        <td class=detail valign=top><b>SOLD TO:</b><br>^;
        
        print "$form{cust_company}<br>" if ($form{cust_company});
        
        print qq^               
                $form{cust_bfname} $form{cust_blname}<br>
                $form{cust_badd1}<br> ^;

        if ($form{cust_badd2}) {
                #print "$form{cust_badd2}<br>";
        }
        print qq^ $form{cust_bcity}, $form{cust_bstate} $form{cust_bzip}<br>
                $form{cust_email}<br><br><b>CARD TYPE:</b> $form{ord_pay_method}<br>
                <b>CARD NO:</b> $temp_ccnum<br><b>EXP:</b> $form{cust_ccmo}/$form{cust_ccyear}<br>
                        <b>CARDHOLDER:</b> $form{cust_ccname}
        </td><td class=detail valign=top><b>SHIP TO:</b><br>^;
        print "$form{cust_scompany}<br>" if ($form{cust_scompany});
        print qq^$form{cust_sfname} $form{cust_slname}<br>
                        $form{cust_sadd1}<br>^;
        print "$form{cust_sadd2}" if ($form{sadd2});
        print qq^$form{cust_scity}, $form{cust_sstate} 
        $form{cust_szip}<br><br><b>SHIP METHOD:</b> $form{ord_ship_method}      
        </td></tr><tr><td valign=top colspan=3>^;
                        
        &cart_display_summary();

        print qq^       </td></tr>
                        </table>
                    </TD></TR>

                    <TR><TD colspan=3 style="text-align:center"> ^;
                
        foreach $key (sort keys %form) {
            if ($key =~ m/^cust_/) {
                    print "<input type=hidden name=$key value=\"$form{$key}\">\n";
            }
        }

        print qq^ <input type=hidden name=ord_pay_method value=\"$form{ord_pay_method}\">
                        <input type=hidden name=ord_ship_method value=\"$form{ord_ship_method}\">
                        <input type=hidden name=discount value=\"$form{discount}\">
                        <input type=hidden name=ON_discount value="$form{ON_discount}">
                        <input type=hidden name=ord_total value=\"$form{ord_total}\">
                        <input type=hidden name=ord_ship_struct value=\"$form{ord_ship_struct}\">
                        <input type=hidden name=handling value=\"$form{handling}\">
                        <br>
                        If your order is correct, press this button to submit your order. 
                        If you need to change something, use your browser's \"Back\" button 
                        to go back and
                        make your changes. By clicking this button to place your order,
                        you are agreeing to all of our store policies. Thank you.<br><br><br>
                 
                <input class=formButton style="font-size:14pt" name="ordSubmitBut" type=submit value=\"Submit Order\"></form> ^;                          
    

} 
########################## END SUB cart_summary ###############################
###############################################################################

###############################################################################
########################### ORDER SUBMISSION SUB ##############################         
sub cart_submit() {
            
    local ($inv_no, $order_insert);
    
    my $ordCheck = $DB_edirect->selectrow_array("SELECT inv_no FROM orders
                                    WHERE session_id = '$form{sid}'");
    if ($ordCheck) {
            print qq^<tr><td style="padding-top:20px" style="text-align:center">
                            <table width=400 border=0>
                            <tr><td style="text-align:center"><br><br>
                            <b>Your order has already been placed, you don't need to        
                            re-submit.<br><br>
                            For future reference, your order number is $ordCheck.  Thank you
                            for shopping  USACabinetHardware.com!</b>
                            </td></tr>
                            </table>
                            </td></tr>^;
            &page_footer();
            &track_session("$session_id", 'CHECKOUT->ORDER SUBMIT-{ERROR:DUPORDER}');
            &closeDBConnections();

            exit;
    }
            
    $form{ship_total} = &calc_shipping("$form{ord_ship_method}");

##AUTHORIZE CREDIT CARD       
    @cc_auth_result = &cc_auth();
    
    if ($#cc_auth_result == 0) {
            &track_session("$session_id", 'CHECKOUT->ORDER SUBMIT-{ERROR:CCAUTHERROR}');    
            return;
    } 

##GET AND SET INVOICE NUMBER FOR ORDER        
    $form{inv_no} = $DB2_edirect->selectrow_array("SELECT max(inv_no + 1) FROM orders");
        
    ## INSERT CREDIT CARD LOG INFO INTO TABLE CC_TRANS_LOG
    $ST_DB = $DB_edirect->do("INSERT INTO cc_trans_log(inv_no, trans_id, trans_type, 
                                                trans_date, trans_amt, approval_code, cust_ccnum, 
                        cust_ccexp, cust_cccode)
                                        VALUES($form{inv_no}, '$cc_auth_result[1]', 'AUTH_CAPTURE', 
                                        NOW(), $form{ord_total}, '$cc_auth_result[0]', 
                                        ENCODE('$form{cust_ccnum}', '3f6bjPT7'), 
                        '$form{cust_ccmo}$form{cust_ccyear}', 
                        '$form{cust_cccode}')");
                                  
  ## LOCK customer, orders, AND order_details TABLES FOR THIS SESSION
    $ST_DB2 = $DB2_edirect->do("LOCK TABLES customers WRITE, orders WRITE, 
                order_details WRITE");
        
        
  ##REMOVE SPACES, PAREN AND DASHES FROM PHONE NUMBER   
    if ($form{cust_bphone}) {
            $form{cust_bphone} =~ s/\s//g;
            $form{cust_bphone} =~ s/\D//g;
            if (length($form{cust_bphone}) > 10) {
                    $form{cust_bphone} =~ s/^\d//;
            }
    }



#       $form{inv_no} = 500 if ($form{inv_no} > 1000);
        
  ######        
  # BUILD CUSTOMER INFO SQL STATEMENT AND INSERT INTO CUSTOMERS
  ######                
        if (!$form{cust_id}) {
                $form{cust_id} = $DB2_edirect->selectrow_array("SELECT max(cust_id + 1) FROM customers");

#               $form{cust_id} = 500 if ($form{cust_id} > 1000);
                                
                $q_company = $DB_edirect->quote($form{cust_company});
                $q_bfname = $DB_edirect->quote($form{cust_bfname});
                $q_blname = $DB_edirect->quote($form{cust_blname});
                $q_badd1 = $DB_edirect->quote($form{cust_badd1});
                $q_badd2 = $DB_edirect->quote($form{cust_badd}) if ($form{cust_badd2});
                $q_bcity = $DB_edirect->quote($form{cust_bcity});
                $q_uid = $DB_edirect->quote($form{cust_uid}) if ($form{cust_uid});
                $q_pwd = $DB_edirect->quote($form{cust_pwd}) if ($form{cust_pwd});
                $q_ccname = $DB_edirect->quote($form{cust_ccname});
                $q_email = $DB_edirect->quote($form{cust_email});
                
                my $cid_insert = "INSERT INTO customers(cust_id";
                
                $cid_insert .= ", cust_company" if ($form{cust_company});
                
                $cid_insert .= ", cust_fname, cust_lname, cust_add1";
                
                if ($form{cust_badd2}) {
                        $cid_insert .= ", cust_add2";
                }
                if ($form{cust_uid} && $form{cust_pwd}) {
                        $cid_insert .= ", cust_userid, cust_pwd";
                }
                $cid_insert .= ", cust_city, cust_state, cust_zip, cust_phone, cust_country,  
                                        cust_email) 
                                        VALUES('$form{cust_id}'";
                                        
                $cid_insert .= ", $q_company" if ($form{cust_company});
                
                $cid_insert .= ", $q_bfname, 
                                        $q_blname, $q_badd1";
                
                if ($form{cust_badd2}) {
                        $cid_insert .= ", $q_badd2";
                }
                if ($form{cust_uid} && $form{cust_pwd}) {
                        $cid_insert .= ", $q_uid, $q_pwd";
                }
                
                $cid_insert .= ", $q_bcity, '$form{cust_bstate}', '$form{cust_bzip}', 
                                        '$form{cust_bphone}', '$form{cust_bctry}', 
                                        $q_email)";
                                        
                $ST_DB2 = $DB2_edirect->do("$cid_insert"); 
        } 
        
   ######       
  # BUILD ORDER INSERT SQL STATEMENT AND INSET INTO ORDERS
  ######        
   #MAKE SURE SHIPPING INFO IS UPPER CASE IN CASE THE USER CHANGES THE INFO ON SUMMARY PAGE
    $form{cust_scompany} = uc $form{cust_scompany} if ($form{cust_scompany});
        $form{cust_sfname} = uc $form{cust_sfname};
        $form{cust_slname} = uc $form{cust_slname};
        $form{cust_sadd1} = uc $form{cust_sadd1};
        $form{cust_sadd2} = uc $form{cust_sadd2} if ($form{cust_sadd2});
        $form{cust_scity} = uc $form{cust_scity};  
   #QUOTE AND ESCAPE STINGS BEFORE INSERTING INTO DBASE
    $q_scompany = $DB_edirect->quote($form{cust_scompany}) if ($form{cust_scompany});
        $q_sfname = $DB_edirect->quote($form{cust_sfname});
        $q_slname = $DB_edirect->quote($form{cust_slname});
        $q_sadd1 = $DB_edirect->quote($form{cust_sadd1});
        $q_sadd2 = $DB_edirect->quote($form{cust_sadd2}) if ($form{cust_sadd2});
        $q_scity = $DB_edirect->quote($form{cust_scity});
        $q_notes = $DB_edirect->quote($form{ord_ship_struct});
        
        if (!$form{handling}) {
                $form{handling} = 0;
        }
        
        $order_insert = "INSERT INTO orders(inv_no, cust_id, inv_date";
        
        $order_insert .= ", ship_company" if ($form{cust_scompany});
        
        $order_insert .= ", ship_fname, ship_lname, ship_add1";
        
        if ($form{cust_sadd2}) {
                $order_insert .= ", ship_add2";
        }
        $order_insert .= ", ship_city, ship_state, ship_zip, ship_country, 
                                                ship_method, ship_cost";
                                                
        $order_insert .= ", salestax" if ($form{salestax});
        
        $order_insert .= ", status, status_date";
        
        if ($form{ord_ship_struct}) {
                $order_insert .= ", cust_notes";
        } 
        
        $order_insert .= ', site_id, total_discount, handling, session_id)';
        
        
        $order_insert .= "  VALUES('$form{inv_no}', '$form{cust_id}', NOW()";
        
        $order_insert .= ", $q_scompany" if ($form{cust_scompany});
        
        $order_insert .= ", $q_sfname, $q_slname, $q_sadd1";
                                        
        if ($form{cust_sadd2}) {
                $order_insert .= ", $q_sadd2";
        }
                
        $order_insert .= ", $q_scity, '$form{cust_sstate}', '$form{cust_szip}', 
                                        '$form{cust_sctry}', '$form{ord_ship_method}', $form{ship_total}";
                                        
        $order_insert .= ", $form{salestax}" if ($form{salestax});
        
        $order_insert .= ", 'NEW', NOW()";
                                        
        if ($form{ord_ship_struct}) {
                $order_insert .= ", $q_notes";
        } 
        
        if (!exists($form{discount}) || $form{discount} eq '') {
                $form{discount} = 0;
        }
        if (!exists($form{handling}) || $form{handling} eq '') {
                $form{handling} = 0;
        }
        $form{discount} = sprintf("%.2f", $form{discount});
        $order_insert .= ", '$site_id', $form{discount}, $form{handling}, '$session_id')";
        
        $ST_DB2 = $DB2_edirect->do("$order_insert"); 
        
   
  # SELECT ITEMS FROM CART AND INSERT INTO ORDER DETAILS        
        $ST_DB = $DB_edirect->prepare("SELECT line_no, qty, c.prod_id, price, disc_qty, disc_amt
                                                FROM cart c, products p
                                                WHERE c.session_id = '$form{sid}'
                                                and c.site_id = '$site_id'
                                                and c.prod_id = p.prod_id");
        $ST_DB->execute();
        while (my @items = $ST_DB->fetchrow_array()) {
                my $discount = 0;
                my ($line, $qty, $prod_id, $price, $disc_qty, $disc_amt) = @items;
                if (($disc_qty != 0) && ($qty >= $disc_qty)) {
                        $discount = &calcDiscount($qty, $price, $disc_amt);
                }
                $price = sprintf("%.2f", $price);
                $ST_DB2 = $DB2_edirect->do("INSERT INTO order_details(inv_no, line_no, prod_id, 
                                qty_ordered, ext_price, disc_amt)
                                 VALUES('$form{inv_no}', '$line', '$prod_id', '$qty', $price, $discount)");
        }
        $ST_DB->finish();

  ## UNLOCK customers, orders, AND order_details TABLES FOR THIS SESSION
    $ST_DB2 = $DB2_edirect->do("UNLOCK TABLES");
  
        ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
        $year += 1900;
        $mon++;
        if ($hour >= 12) {
                $hour = $hour - 12 if ($hour > 12);
                $am_pm = "PM";
        } else {
                $am_pm = "AM";
        }
        
        if ($min < 10) {
                $min = '0' . $min;
        }

     &track_session("$session_id", 'CHECKOUT->ORDER SUBMIT');
            
                    
        print qq^<TR><TD><H2 class=top>CHECKOUT->ORDER RECEIPT - ORDER# $form{inv_no} </H2></TD></TR>
                        <TR><TD style="text-align:center">
                        <table width=600 border=1 cellpadding=3 cellspacing=0 bordercolor=000000>
                        <tr>
                        <td colspan=2><b>DATE: $mon/$mday/$year</b></td>
                        </tr>
                        <tr><td width=50\% valign=top class=detail><b>BILLING:</b><br>^;
                
        print "$form{cust_company}<br>" if ($form{cust_company});
                
        print qq^ $form{cust_bfname} $form{cust_blname}<br>
                                $form{cust_badd1}<br>^;
                
        if ($form{cust_badd2}) {
                print qq^$form{cust_badd2}<br>^;
        }
        print "$form{cust_bcity}, $form{cust_bstate} $form{cust_bzip}\n";
#       print "<br>$countries{$form{cust_bctry}}" if ($form{cust_bctry} ne 'us');
        print "</td><td valign=top class=detail><b>SHIPPING:</b><br>";
                                
        print "$form{cust_scompany}<br>" if ($form{cust_scompany});
                
        print qq^$form{cust_sfname} $form{cust_slname}<br>
                                $form{cust_sadd1}<br> ^;
                                
        if ($form{cust_sadd2}) {
                print qq^$form{cust_sadd2}<br>^;
        }
        print "$form{cust_scity}, $form{cust_sstate} $form{cust_szip}<br>\n";
#       print "$countries{$form{cust_sctry}}" if ($form{cust_sctry} ne 'us');
        print "</td></tr>";
        
        print qq^ <tr><td colspan=2>
                                <table border=0 cellpadding=2 cellspacing=0 width=100%>
                                <tr bgcolor=\"#C5CDEZ\"><th class=detail>QTY</th><th class=detail>PROD ID</th>
                                <th class=detail>SIZE</th><th class=detail>FINISH</th><th class=detail>UNIT</th>
                                <th class=detail>PRICE</th><th class=detail>TOTAL</th></tr>
                                ^;

        my $temp_file = $root_dir . 'e_tmp/O-' . $form{inv_no} . '.txt';
                                        
        open(TEMPFILE, ">$temp_file") or die "Can't open FILE $temp_file at sub submit";

        print TEMPFILE "EVERYTHING DIRECT - USACabinetHardware.com\n";
        print TEMPFILE "ORDER #$form{inv_no}\nTIME/DATE: $hour:$min$am_pm $mon/$mday/$year\n\n";
        print TEMPFILE "SOLD TO:\n";
                
        print TEMPFILE "$form{cust_company}\n" if ($form{cust_company});
                
        print TEMPFILE "$form{cust_bfname} $form{cust_blname}\n$form{cust_badd1}\n";
                                
        if ($form{cust_badd2}) {
                print TEMPFILE "$form{cust_badd2}\n";
        }       
        print TEMPFILE "$form{cust_bcity}, $form{cust_bstate} $form{cust_bzip}\n$form{cust_email}\n\nSHIP TO:\n";

        print TEMPFILE "$form{cust_scompany}\n" if ($form{cust_scompany});
                
    print TEMPFILE "$form{cust_sfname} $form{cust_slname}\n$form{cust_sadd1}\n";
    if ($form{cust_sadd2}) {
        print TEMPFILE "$form{cust_sadd2}\n";
    }
    print TEMPFILE "$form{cust_scity}, $form{cust_sstate} $form{cust_szip}\n";
    print TEMPFILE "$countries{$form{cust_sctry}}\n" if ($form{cust_sctry} ne 'us');
    print TEMPFILE"\n";    

        print TEMPFILE "\nPLEASE KEEP THIS RECEIPT FOR ANY FUTURE REFERENCE\n";    
    print TEMPFILE"-" x 78 . "\n";
    select(TEMPFILE);
format RECEIPTHD =
@<<<< @<<<<<<<<<<<<<< @<<<<<<<<<<<< @<<<<<<<<<<<<<<< @<<<<< @>>>>>>> @>>>>>>>>
QTY,ID,SIZE,FINISH,UNIT,PRICE,TOTAL
.               
    $~ = "RECEIPTHD";           
    write TEMPFILE;
    print TEMPFILE "-" x 78 . "\n";
    select(STDOUT);
    
    # PREPARE SQL FOR EXECUTION
    $ST_DB = $DB_edirect->prepare("SELECT DISTINCT od.qty_ordered, od.prod_id, 
                                p.size1, p.finish, p.unit, p.price 
                            FROM order_details AS od, products AS p
                                WHERE od.inv_no = '$form{inv_no}'
                            and od.prod_id = p.prod_id");
                                
                                
    # EXECUTE SQL               
    $ST_DB->execute();
    my ($sub_total, $ord_total);        
    while (@results = $ST_DB->fetchrow_array()) {
        my ($qty, $prod_id, $size, $finish, $unit, $price) = @results;
        $price = sprintf("%.2f", $price);
        my $prod_total = $qty * $price;
        $sub_total += $prod_total;
        $prod_total = sprintf("%.2f", $prod_total);
        print "<tr>
                         <td class=detail>$qty</td><td class=detail>$prod_id</td>
                         <td class=detail>$size</td><td class=detail>$finish</td><td class=detail>$unit</td>
                        <td class=detail>$price</td><td align=right class=detail>$prod_total</td></tr>"; 
        select(TEMPFILE);
format RECEIPT =
@<<<< @<<<<<<<<<<<<<< @<<<<<<<<<<<< @<<<<<<<<<<<<<<< @<<<<< @####.## @#####.##
$qty,$prod_id,$size,$finish,$unit,$price,$prod_total
.                       
        $~ = "RECEIPT";         
        write TEMPFILE;
        select(STDOUT);
        $prod_total = 0;
    }
    $ST_DB->finish();
    print TEMPFILE "-" x 78 . "\n";
    
    if ($form{discount}) {
        $sub_total -= $form{discount};
    }
    
    $sub_total = sprintf("%.2f", $sub_total);
    
    print TEMPFILE "\nOrder Discount: -\$${form{discount}}\nSub Total: \$${sub_total}";
    print qq^</table</td></tr>
                <tr>
                <td colspan=7 align=right class=detail>ORDER DISCOUNT: -\$${form{discount}}</td></tr>
                <tr>
                <td colspan=7 align=right class=detail>SUB TOTAL: \$${sub_total}</td></tr>^;
    
    if ($form{salestax}) {
        $sub_total += $form{salestax};          
        print TEMPFILE "\nND Sales Tax: \$$form{salestax}";
        print qq^<tr><td colspan=7 align=right class=detail>ND SALES TAX: \$$form{salestax}</td></tr>^;
    }           
    
    print TEMPFILE "\nShipping: \$${form{ship_total}}";
    print qq^<tr>
                <td colspan=7 align=right class=detail>SHIPPING: \$${form{ship_total}}</td></tr>^;
    
    if ($form{handling}) {
        $sub_total += $form{handling};
        print TEMPFILE "\nHandling: \$$form{handling}";
        print qq^<tr><td colspan=7 align=right class=detail>HANDLING: \$$form{handling}</td></tr>^;
    }           
                                                                
    $ord_total = $sub_total + $form{ship_total};
    $ord_total = sprintf("%.2f", $ord_total);
        
    print TEMPFILE "\nGrand Total: \$${ord_total}\n";
    print TEMPFILE "\nShipping Method: $form{ord_ship_method}\nPayment Method: $form{ord_pay_method}\n\nTHIS CHARGE WILL APPEAR ON YOUR CREDIT CARD AS \"EVERYTHING DIRECT NV\"\n\nThank you for ordering from USACabinetHardware.com! You can check the status of your order by clicking here\n${cgi_url}usacare.pl?a=os&inv_no=$form{inv_no}\nIf your order is incorrect for any reason, please e-mail us immediately at\nmailto:${return_mail}?Subject=Order#$form{inv_no}_Inquiry";
    print TEMPFILE "\nOR call us at 1.877.281.7905!\n\n-----RETURN INFORMATION------\nIf you need to return an item from this order, please follow our return process by clicking here:\nhttp://www.usacabinethardware.com/policies.html#returns\n\n";
    
#    if ($form{cust_uid} && $form{cust_pwd} && $form{handling}) {
#        print MAIL "\n\nIf your next order is over \$50, use this code to receive a $5 discount: HFD13\n";
#    }
    
    close (TEMPFILE);
            
    $email_subject = 'USACabinetHardware.com Order Receipt - ' . $form{inv_no};
    $email_message = 'FILE-TO-SEND--' . $temp_file;
        
    &email_send("$form{cust_email}", "$return_mail", "$email_subject", "$email_message", "$return_mail");
        
    remove($temp_file);
                                        
    print qq^<tr>
                <td colspan=7 align=right class=detail>GRAND TOTAL: \$${ord_total}</td></tr>
                <tr>
                <td colspan=7 class=detail>Shipping Method: $form{ord_ship_method}
                </td></tr>
                <tr>
                <td colspan=7 class=detail>Payment Method: $form{ord_pay_method}
                </td></tr>
                <tr>
                <td colspan=7 class=detail>Thank you for your order. Please 
                print this receipt for your records.  You should also receive an 
                e-mail receipt shortly.
                </td></tr>
                </table>
                </TD></TR>
                <TR><TD colspan=2 style="text-align:center">
                <font size=2>Your payment information has been securely routed 
                        and approved by 
                        <a href="http://www.authorize.net">Authorize.Net</a>.<br><br>
                        <div style="font-weight:bold;color:red;text-align:center">
                                PLEASE BE AWARE<br>
                                THIS CHARGE WILL APPEAR ON YOUR CREDIT CARD AS "EVERYTHING DIRECT NV"</div></font><br><br>
                                
<!-- Google Code for Purchase Conversion Page -->
<script language="JavaScript" type="text/javascript">

var google_conversion_id = 1072656309;
var google_conversion_language = "en_US";
var google_conversion_format = "1";
var google_conversion_color = "999999";
if (30.0) {
  var google_conversion_value = 30.0;
}
var google_conversion_label = "Purchase";
//-->
</script>
<script language="JavaScript" src="https://www.googleadservices.com/pagead/conversion.js">
</script>
<noscript>
<img height=1 width=1 border=0 src="https://www.googleadservices.com/pagead/conversion/1072656309/?value=30.0&label=Purchase&script=0">
</noscript>
<br><br>
<!-- MSN Adcenter Code for Purchase Conversion Page -->
<SCRIPT>
microsoft_adcenterconversion_domainid = 169668;
 microsoft_adcenterconversion_cp = 5050; 
 </script>
<SCRIPT SRC="https://0.r.msn.com/scripts/microsoft_adcenterconversion.js"></SCRIPT>
<NOSCRIPT><IMG width=1 height=1 SRC="https://169668.r.msn.com/?type=1&cp=1"/></NOSCRIPT><a href="http://advertising.msn.com/MSNadCenter/LearningCenter/adtracker.asp" target="_blank">::adCenter::</a>
                                                  
                </TD></TR>
                </table>
                </td></tr> ^;
    
   
    ##INCREMENT NUMBER OF ORDERS CUSTOMER HAS PLACED    
    $ST_DB2 = $DB2_edirect->prepare("SELECT cust_numorders FROM customers  
                        WHERE cust_id = $form{cust_id}");
    $ST_DB2->execute();
    @numorders = $ST_DB2->fetchrow_array();
    $ST_DB2->finish();
    $numorders[0] += 1;
    $ST_DB = $DB_edirect->do("UPDATE customers SET cust_numorders = $numorders[0]
                                WHERE cust_id = $form{cust_id}");                          
    
    ##REMOVE SHOPPING CART AND SESSION FROM DATABASE                            
    &cart_clear();

} 
################################## END SUB SUBMIT #############################
###############################################################################

############################################################################### 
######################### CATALOG browse SUBROUTINE ###########################
sub cat_browse() {
    my ($query, $count_query, $group_count_query, $cid1, $cid2, $node_tree);

    $query = "SELECT SQL_CALC_FOUND_ROWS STRAIGHT_JOIN DISTINCT b.brand_id, brand, model_num, group_id, p.prod_id,  
            detail_descp, size1, size2, finish, unit, price, disc_qty, disc_amt, 
            stock, qty_oh, ship_time";

    if (length($form{cnid}) == 2) {
        $query .= " FROM store_departments AS d
                    LEFT JOIN store_aisles AS a USING(dept_id)
                    LEFT JOIN store_sections AS s USING(aisle_id)
                    LEFT JOIN store_shelves AS sh USING(section_id)
                    LEFT JOIN prod_to_store AS pts USING(shelf_id)
                    LEFT JOIN products AS p USING(prod_id)
                    LEFT JOIN brands AS b USING(brand_id)
                    WHERE d.store_id = $form{cnid}";
    } elsif (length($form{cnid}) == 3) {
        $query .= " FROM store_aisles AS a 
                    LEFT JOIN store_sections AS s USING(aisle_id)
                    LEFT JOIN store_shelves AS sh USING(section_id)
                    LEFT JOIN prod_to_store AS pts USING(shelf_id)
                    LEFT JOIN products AS p USING(prod_id)
                    LEFT JOIN brands AS b USING(brand_id)
                    WHERE a.dept_id = $form{cnid}";
    } elsif (length($form{cnid}) == 4) {
        $query .= " FROM store_sections AS s 
                    LEFT JOIN store_shelves AS sh USING(section_id)
                    LEFT JOIN prod_to_store AS pts USING(shelf_id)
                    LEFT JOIN products AS p USING(prod_id)
                    LEFT JOIN brands AS b USING(brand_id)
                    WHERE s.aisle_id = $form{cnid}";
    } elsif (length($form{cnid}) == 5) {
        $query .= " FROM store_shelves AS sh 
                    LEFT JOIN prod_to_store AS pts USING(shelf_id)
                    LEFT JOIN products AS p USING(prod_id)
                    LEFT JOIN brands AS b USING(brand_id)
                    WHERE sh.section_id = $form{cnid}";
    } elsif (length($form{cnid}) == 6) {
        $query .= " FROM prod_to_store AS pts
                    LEFT JOIN products AS p USING(prod_id)
                    LEFT JOIN brands AS b USING(brand_id)
                    WHERE pts.shelf_id = $form{cnid}";
    } else {
        $query .= " FROM prod_to_store AS pts
                    LEFT JOIN products AS p USING(prod_id)
                    LEFT JOIN brands AS b USING(brand_id)
                    WHERE";
    }
                                        


    if (exists($form{bid}) && $form{bid} ne 'ALL' && $form{bid} ne '') {
            if (substr("$query", -5) eq 'WHERE') {
                $query .= " b.brand_id = '$form{bid}'";
            } else {    
                $query .= " and b.brand_id = '$form{bid}'";
            }
    } 
                
    if (exists($form{finish}) && $form{finish} ne 'ALL' && $form{finish} ne '') {
            if (substr("$query", -5) eq 'WHERE') {
                    $query .= " finish = '$form{finish}'";

            } else {
                    $query .= " and finish = '$form{finish}'";      
         
            }                       
    } 

    if (exists($form{size}) && $form{size} ne 'ALL' && $form{size} ne '') {
            my $searchSize = $form{size};
            $searchSize =~ s/in/"/g;
            $searchSize = $DB_edirect->quote("$searchSize");

            if (substr("$query", -5) eq 'WHERE') {
                    $query .= " size1 = $searchSize";

            } else {
                    $query .= " and size1 = $searchSize";      
         
            }                       
    }                 
           


    $query .= " and status != 0 
                GROUP BY group_id, model_num";
    
    if (exists($form{sortBy}) && $form{sortBy} ne '') {
        my ($field, $order) = split(/-/, $form{sortBy});
        $query .= " ORDER BY $field $order";
    } else {
        $query .= " ORDER BY p.brand_id, p.prod_id";
    }

    if (exists($form{ind}) && $form{ind} != 0) {
            $query .= " LIMIT $form{ind}, 20";
            $form{ind} += 20;
    } else {
            $form{ind} = 20;
            $query .= " LIMIT 20";
    }
    
    &cat_display_page("$query"); 
        
}
############################### END SUB browse ################################                                                                                                                                                                                                                                                                         
###############################################################################

################################################################################
######################## DISPLAY CATALOG detail_item SUBROUTINE ################
sub cat_detail_item() {
        my ($detail_query, @result, $bid, $group_id, $test, @group_descp);
        
        $bid = $DB_edirect->selectrow_array("SELECT brand_id FROM products
                                WHERE prod_id = '$form{pid}'");
                                
        $test = $DB_edirect->selectrow_array("SELECT group_id FROM products 
                                                WHERE prod_id = '$form{pid}'
                                                and group_id is not null");

  #CHECK TO SEE IF PRODUCT GROUP EXISTS, IF IT DOES, DO THE FIRST BRANCH OF CODE        
        if ($test) {
                $group_id = $test;
                @group_descp = $DB2_edirect->selectrow_array("SELECT b.brand_id, brand,
                                                detail_descp, prod_id, ship_time, model_num, stock                        
                                                FROM brands b, products p
                                                WHERE group_id = '$group_id'
                                                and p.brand_id = b.brand_id");
                                                
                $group_descp[6] = $DB2_edirect->selectrow_array("SELECT descp 
                                                        FROM product_descp 
                                                        WHERE descp_id = '$group_id'");
                                                                
                $group_descp[7] = $DB2_edirect->selectrow_array("SELECT cat_id 
                                                FROM prod_to_cat
                                                WHERE prod_id = '$group_descp[3]'");   
                
                my $ship_time = $DB_edirect->selectrow_array("SELECT st_text FROM ship_time
                                WHERE st_code = $group_descp[4]");
                                
                                
                print qq^<tr><td><table border=0 width=100%>
                                  
                                  <tr><td>
                                  <button class=formButton onClick="javascript:history.back()">&lt;&lt;
                                  PREVIOUS PAGE</button></td></tr>^;

                                        
                print qq^<tr><td align=right style="padding-top:20px" class="detail">
                                        To add an item to your cart, 
                                        enter the quantity,<br>
                                        select size and color, then 
                                        click the <b>\"ADD TO CART\" button</b>.                          <div style="display:inline;margin-left:0px;float:right">
<!-- AddThis Button BEGIN -->
<div class="addthis_toolbox addthis_default_style" style="display:inline">
<a href="http://www.addthis.com/bookmark.php?v=250&amp;username=xa-4b43a97c04645153" class="addthis_button_compact">Share</a>
<span class="addthis_separator">|</span>
<a class="addthis_button_facebook"></a>
<a class="addthis_button_myspace"></a>
<a class="addthis_button_google"></a>
<a class="addthis_button_twitter"></a>
</div>
<script type="text/javascript" src="http://s7.addthis.com/js/250/addthis_widget.js#username=xa-4b43a97c04645153"></script>
<!-- AddThis Button END -->
                         </div>   
                         </td></tr>
                                        <tr><form method=post action=${cgi_url}usastore.pl name="cartForm">
                                        <input type=hidden name=a value=cart_add>
                                        <td style="text-align:center">
                                        <hr noshade size=1 width=100%>
                                        <table border=0 cellpadding=5 cellspacing=0 width=740>
                                        <tr><td class=detail>
                                        <h1>$group_descp[1]</h1></td><td rowspan=6>^;
                if (-e "${home_dir}img/products/$group_descp[0]/$group_descp[4].jpg") {
                       print qq^<a href=\"javascript: productView('${img_url}products/$group_descp[0]/$group_descp[3].jpg', '$group_descp[2]')">    
                        <img src=\"${img_url}products/$group_descp[0]/$group_descp[3].jpg\" border=0 width=220>^;
                } elsif (-e "${home_dir}img/products/$group_descp[0]/${group_id}.jpg") {
                       print qq^ <a href=\"javascript: productView('${img_url}products/$group_descp[0]/${group_id}.jpg', '$group_descp[2]')\">
                                                <img src=\"${img_url}products/$group_descp[0]/${group_id}.jpg\" width=220 border=0>^;
                } else {
                       print "IMAGE IS NOT AVAILABLE";
                }
                                        
                                        print qq^</a><br>
                                        <font size=2>Click image for possible larger 
                                        view.</font></td></tr>
                                        <tr><td class=detail>
                                        <b>MODEL #:</b> $group_descp[5]</td></tr>
                                        <tr><td class=detail><b>DESCRIPTION:</b>&nbsp;$group_descp[2]</td></tr>             
                                        <tr><td class=small> $group_descp[6]^;

                                        
#####GET AND PRINT PRODUCT FEATURES     
                $ST_DB = $DB_edirect->prepare("SELECT feature FROM product_features
                                        WHERE feature_id = '$group_id'"); 
                $ST_DB->execute();        
                
                if ($ST_DB->rows != 0) {
                    print "<br><br><b><u>FEATURES</u></b><ul>";

                
                    while (my $feature = $ST_DB->fetchrow_array()) {
                        print qq^ <li>$feature</li>^;
                    }
                    
                    print "</ul>";
                }
                
        #accessories/related
                #GET AND PRINT ACCESSORIES FOR THIS PRODUCT
                $ST_DB = $DB_edirect->prepare("SELECT acc_mid1, acc_did1, p.detail_descp        
                                             FROM accessories a, products p
                                             WHERE acc_mid2 = '$group_descp[0]'
                                             and acc_gid2 = '$group_id'
                                             and acc_did1 = p.prod_id");
                $ST_DB->execute();
                
                if ($ST_DB->rows != 0) {
                    print "<br><br><b><u>RELATED ITEMS</u></b><br>";
                    if (my ($acc_mid, $acc_pid, $descp) = $ST_DB->fetchrow_array()) {
                            do {    
                    
                            print qq^&nbsp;&nbsp;&nbsp;&nbsp;
                    <a href=\"${cgi_url}usastore.pl?a=di&pid=${acc_pid}\">      
                                                    $descp</a><br>^;
                            } while (($acc_mid, $acc_pid, $descp) = $ST_DB->fetchrow_array());                        
                    } else {
                            print "<i>( NONE )</I><br><br>";
                    }
                }
                
                my $coll_id = $DB_edirect->selectrow_array("SELECT coll_id FROM collection_items WHERE brand_id = '$group_descp[0]' and prod_id = '$group_descp[3]'");

                if ($coll_id) {
                          print qq^<br><br><b><u>RELATED ITEMS</u></b><br>
                          <a href="usacollect.pl?st=2&bid=$group_descp[0]&cid=$coll_id">MATCHING COLLECTION PIECES</a><br><br>^;
                }
                                       
                $ST_DB->finish(); 

                my $printFlag = 1;
                print "<br><b><u>SPECIFICATIONS</u></b><br>";   
                                        
#GET AND PRINT SPECIFICATIONS FOR THIS PRODUCT
#                $ST_DB2 = $DB2_edirect->prepare("SELECT sub_head, spec 
#                                               FROM product_specs_tab
#                                               WHERE group_id = '$group_id'
#                                               ORDER BY group_id, col");
#                $ST_DB2->execute();
#                $specs = $ST_DB2->fetchall_arrayref();
#                $ST_DB2->finish();
                                
#                if (@$specs != 0) {
#                        $count =0;
#                        my @sp_line2;
#                        print qq^
#                                        <table cellpadding=3 cellspacing=0 border=1><tr>
#                                        <th class=tiny>ITEM#</th>^;
#                        foreach $spec (@$specs) {
#                                my ($sh, $sp) = @$spec;
#                                push @sp_line2, $sh if($sh);
#                                print "<th class=tiny>$sp</th>";                                
#                        }
#                        print "</tr>";
#                        if (@sp_line2) {
#                                print "<tr><th></th>";
#                                foreach my $spl2 (@spec_line2) {
#                                        print "<th class=tiny>$spl2</th>";
#                                }
#                                print "</tr>";
#                        }
#                        $ST_DB = $DB_edirect->prepare("SELECT prod_id, detail 
#                                                                FROM product_specs
#                                                                WHERE group_id = '$group_id'
#                                                                ORDER BY detail_id, col");
#                        $ST_DB->execute();
#                        my ($did, $det) = $ST_DB->fetchrow_array();
#                        $didHold = $did;
#                        print "<tr><td class=tiny>$did</td>";
#                        do {
#                                if ($didHold ne $did) {
#                                        print "</tr><tr><td class=tiny>$did</td>";
#                                        $didHold = $did;
#                                }
#                                print "<td class=tiny>$det</td>";
#                        } while (($did, $det) = $ST_DB->fetchrow_array());
#                        $ST_DB->finish();
#                        print "</table>";       
#                }
                
                
    ##DETERMINE IF SPEC IMAGE EXISTS, IF SO PRINT LINK
                if (-e "${home_dir}img/specs/$group_descp[0]/spec-${group_id}\.jpg") {
                        print qq^&nbsp;&nbsp;&nbsp; <a href=\"javascript: productView('${img_url}specs/$group_descp[0]/spec-${group_id}.jpg', '$group_descp[2]')\">Click For Spec Image</a><img src="${img_url}specs/$group_descp[0]/spec-${group_id}.jpg" border=0 width=20 height=20>^;
                } elsif (-e "${home_dir}img/specs/$group_descp[0]/spec-${group_id}\.gif") {
                        print qq^&nbsp;&nbsp;&nbsp; <a href=\"javascript: productView('${img_url}specs/$group_descp[0]/spec-${group_id}.gif', '$group_descp[2]')\">Click For Spec Image</a><img src="${img_url}specs/$group_descp[0]/spec-${group_id}.gif" border=0 width=20 height=20>^;
                }
                
                ##DETERMINE IF SPEC PDF EXISTS, IF SO PRINT LINK
                if (-e "${home_dir}docs/specs/pdf/$group_descp[0]/${group_id}.pdf") {
                        print qq^&nbsp;&nbsp;&nbsp; <a href="${base_url}docs/specs/pdf/$group_descp[0]/${group_id}.pdf">Click For Spec PDF</a>^;
                } 

        print "</ul>";                
    ##END PRINT SPECIFICATIONS

     ### GET FINISHES AND DISPLAY FINISH IMAGES
     
        $ST_DB = $DB_edirect->prepare("SELECT prod_id, finish FROM products 
                      WHERE brand_id = $group_descp[0] and group_id = '$group_id'
                      ORDER BY finish");
        
        $ST_DB->execute();
        $finishes = $ST_DB->fetchall_arrayref();
        $ST_DB->finish();
        my %finishes;
        
      
        if (@$finishes > 0 && -e "${home_dir}img/finishes/$group_descp[0]/") {
            print qq^<br><br><table bgcolor="#FFE1E1" border="0" cellpadding="5" cellspacing="0" width="100%">
                      <tr><td class=detail colspan=6 style="text-align:center"><b>THIS ITEM AVAILABLE IN THESE FINISHES:</b></td></tr>
                      <tr>^;
            my $count_finish = 0;
            foreach $finish (@$finishes) {
                if ($count_finish == 4) {
                    print "</tr><tr>";
                    $count_finish = 0;
                }
                my (@splits) = split(/-/, @$finish[0]);
                my $finish_code = pop @splits;
                $finishes{$finish_code} = @$finish[1];
                if (-e "${home_dir}img/finishes/$group_descp[0]/$finish_code\.jpg") {
                    print qq^<td class=small style="text-align:center"><a href="javascript:productView('${img_url}finishes/$group_descp[0]/$finish_code\.jpg', '@$finish[1]')">
                            <img border="0" src="${img_url}finishes/$group_descp[0]/$finish_code\.jpg" width="50"></a><br><font size=1>@$finish[1]</font></td>^;
                    
                    $count_finish++;        
                }

            }
            
            print qq^</tr></table><br><br>^;
        }  

     ## END DISPLAY FINISH OPTION IMAGES
     ######################################   
        
        $detail_query = "SELECT brand_id, prod_id, size1, 
                        size2, finish, price, unit, disc_qty, disc_amt 
                        FROM products 
                        WHERE group_id = '$group_id'
                        ORDER BY prod_id, finish";
                                                        
                $ST_DB = $DB_edirect->prepare($detail_query);
                $ST_DB->execute();

                print qq^</td></tr><tr><td class=detail><b>SELECT SIZE/FINISH:<br>
                                       <select class=small name="${group_id}_pid" onChange="document.getElementById('prodDiv').innerHTML=this.value">^;
                
        # INITIALIZE SELECT LIST WITH ITEM SELECTED TO GET TO THIS PAGE        
                my @prod_init = $DB_edirect->selectrow_array("SELECT brand_id, prod_id, size1, 
                                                        size2, finish, price, unit, disc_qty
                                                        FROM products 
                                                        WHERE prod_id = '$form{pid}'
                                                        and status != 0");

                my $spid = $DB_edirect->selectrow_array("SELECT spec_id
                                FROM specials_products
                                WHERE site_id = $site_id
                                and prod_id = '$form{did}'");              
                if ($spid && $spid ne 'NEW') {
                                @$d_result->[5] = &calcSpecial("$spid", "@prod_init[5]");
                }
                @prod_init[5] = sprintf("%.2f", @prod_init[5]);
                        
                print qq^<option value=\"@prod_init[1]\">
                                        @prod_init[2]&nbsp;&nbsp;&nbsp;&nbsp;
                                        @prod_init[3]&nbsp;&nbsp;&nbsp;&nbsp;@prod_init[4] 
                                        &nbsp;&nbsp;&nbsp;&nbsp;\$@prod_init[5]&nbsp;&nbsp;@prod_init[6]</option>^;
                                                                                
                                        
                my $case = 0;            
                while (@result = $ST_DB->fetchrow_array()) {
                        if ($result[8] && $result[8] ne 'NEW') {
                                $result[5] = &calcSpecial("$result[8]", "$result[5]");
                        } else {
                                $result[5] = sprintf("%.2f", $result[5]);
                        }
                        print qq^<option value=\"$result[1]\">
                                        $result[2]&nbsp;&nbsp;&nbsp;&nbsp;
                                        $result[3]&nbsp;&nbsp;&nbsp;&nbsp;$result[4] 
                                        &nbsp;&nbsp;&nbsp;&nbsp;\$$result[5]&nbsp;&nbsp;$result[6]</option>^;
                        $case = $result[7];
                        $disc_amt = $result[8];
                }
                $ST_DB->finish();
                
                print qq^ </select></td></tr>
                                        <tr><td class=detail bgcolor="#FDF2B5" colspan="2"><b>QTY:</b> 
                                <input type=text name=${group_id}_qty value=\"1\" size=4>

                              <div style="padding-left:20px;display:inline;font-weight:bold">ITEM NUMBER:</div>
                              <div style="display:inline;padding-left:5px;padding-right:20px" id="prodDiv">@prod_init[1]</div>
                              
                                      <input type=submit class=formButton value=\"ADD TO CART\"><br></td></tr>^;
                
                
                print qq^<tr><td class=small style="padding-top:5px">
                                        <font color=\"#CAAC02\" ><b>NOTES:<br>
                                        - Normally ships $ship_time</b>^;
                if ($case > 0) {
                    my $count_discounts = $DB_edirect->selectrow_array("SELECT count(DISTINCT disc_qty) FROM products
                                                                  WHERE group_id = '$group_id'");
                    
                    if ($count_discounts > 1) {
                         print qq^<br><b>- Quantity discounts available, add to cart to see discount.<br>^;
                    } else {
                        my $disc_amt = $disc_amt * 100;
                        print qq^<br><b>- $disc_amt\% discount on $case or more!<br>^;
                    }
                }               
                                
                print qq^</font></td></tr></table></td></tr><tr><td style="padding-top:20px">
                              <div style="color:firebrick;font-size:9pt;margin-top:5px;margin-bottom:10px;margin-bottom:10px;margin-left:50px"><span style="font-size:13pt;font-weight:bold">FREE</span>
                                     GROUND SHIPPING ON ORDERS OF \$199 OR MORE!<br>
                                     <span style="font-size:13pt;font-weight:bold">REDUCED</span> GROUND SHIPPING ON ORDERS OF \$100 TO \$199</div>
                                                                           &nbsp;
              <!--         <div style="border:5px dotted green;padding:5px;margin:10px;text-align:center">
                      Hurry and order your hardware now before the annual price increases take effect!
                  </div>   -->
                                  </td></tr>
                                  <tr><td>
                                  <button class=formButton onClick="javascript:history.back()">&lt;&lt;
                                  PREVIOUS PAGE</button></td></tr>
                        
</table></td></tr></form>^;
                
        
        
#################################################                               
        } else {
                
                @result = $DB_edirect->selectrow_array("SELECT brand, p.brand_id, prod_id, 
                                                 model_num, detail_descp, size1, size2, 
                                                 finish, price, unit, 
                                                disc_qty, group_id, ship_time, stock, disc_amt, MAP_price, list
                                                FROM brands b, products p 
                                                WHERE prod_id = '$form{pid}'
                                                and status != 0
                                                and b.brand_id = p.brand_id");

                my $ship_time = $DB_edirect->selectrow_array("SELECT st_text FROM ship_time
                        WHERE st_code = '$result[12]'");
                                                                                

#                if ($result[11] && $result[11] ne 'NEW') {
#                        $result[7] = &calcSpecial("$result[11]", "$result[7]");
#                } else {
                        $result[8] = $result[15] if ($result[15] != 0);  
                        $result[8] = sprintf("%.2f", $result[8]);
#                }
                

                print qq^ <tr><td style="padding-top:20px">
                                 <button class=formButton onClick=\"javascript:history.back()\">&lt;&lt;PREVIOUS PAGE</button></td></tr>^;

                
                print qq^ <tr><td align=right style="padding-top:15px" class=detail>
                                        To add this item to your cart, 
                                        enter the quantity<br> then click the <b>\"ADD TO 
                                        CART\"</b> button.
                          <div style="display:inline;margin-left:0px;float:right">
<!-- AddThis Button BEGIN -->
<div class="addthis_toolbox addthis_default_style" style="display:inline">
<a href="http://www.addthis.com/bookmark.php?v=250&amp;username=xa-4b43a97c04645153" class="addthis_button_compact">Share</a>
<span class="addthis_separator">|</span>
<a class="addthis_button_facebook"></a>
<a class="addthis_button_myspace"></a>
<a class="addthis_button_google"></a>
<a class="addthis_button_twitter"></a>
</div>
<script type="text/javascript" src="http://s7.addthis.com/js/250/addthis_widget.js#username=xa-4b43a97c04645153"></script>
<!-- AddThis Button END -->
                         </div>         
                                        </td></tr>
                                        <tr>
                                        <td colspan=2 style="text-align:center">
                                        <table style="border-top:1px solid;border-left:1px solid" border=0 cellpadding=10 cellspacing=0 width=760>
                                        <tr><td class=detail>
                                        <h1>$result[0]</h1></td><td rowspan=12 class=detail align=right>^;
                                        
        ##DETERMINE IF IMAGE EXISTS AND DISPLAY, ELSE DISPLAY IMAGE_NOT_AVAILABLE
                if (-e "${home_dir}img/products/$result[1]/$result[2]\.jpg") {
                        print "<a href=\"javascript: productView('${img_url}products/$result[1]/$result[2].jpg', '$result[2]')\">
                                <img border=0 src=\"${img_url}products/$result[1]/$result[2].jpg\" width=300></a>";
                } elsif (-e "${home_dir}img/products/$result[1]/$result[10]\.jpg") {
                        print "<a href=\"javascript: productView('${img_url}products/$result[1]/$result[10].jpg', '$result[2]')\">
                                <img border=0 src=\"${img_url}products/$result[1]/$result[10].jpg\" width=300></a>";
                } else {
                        print "<div style=\"font-size:8px\">NO IMAGE AVAILABLE</div>";
                }


                if ($result[13] == 0) {
                        print qq^<br><br><center><font color=#DF0000>THIS IS A NON-STOCK ITEM, PLEASE ALLOW 2 TO 3 WEEKS FOR DELIVERY</font></center>^;
                }
                                        
                print qq^<tr><td class=detail><b>ITEM NO.:</b> $result[2]<br>
                                        <b>MODEL NO.:</b> $result[3]
                                        </td></tr>
                                        
                                        
                                        <tr><td class=detail><b>DESCRIPTION:</b> $result[4]</td></tr>
                                        <tr><td class=detail><b>DIMENSIONS:</b> $result[5]&nbsp;&nbsp;&nbsp;&nbsp;$result[6]</td></tr>
                         <tr><td class=detail><b>FINISH:</b> $result[7]<br><br>^;
                
                my $feat_count = $DB_edirect->selectrow_array("SELECT count(*) FROM product_features
                                                       WHERE feature_id = '$result[2]'");
                                                                                               
        ##
        ## PRODUCT FEATURES
                if ($feat_count > 0) {
                                                             
                     print qq^<br><br><b><u>FEATURES</u></b><ul>^;
                                        
                     #####GET AND PRINT PRODUCT FEATURES     
                     $ST_DB = $DB_edirect->prepare("SELECT feature FROM product_features
                                                        WHERE feature_id = '$result[2]'");       
                     $ST_DB->execute();        
                
                     while (my $feature = $ST_DB->fetchrow_array()) {
                        print "<li>$feature</li>";
                     }
                     print "</ul>";
                } 

    ##DETERMINE IF SPEC IMAGE EXISTS, IF SO PRINT LINK
                if (-e "${home_dir}img/specs/$result[1]/spec-${result[2]}\.jpg") {
                        print qq^&nbsp;&nbsp;&nbsp; <a href=\"javascript: productView('${img_url}specs/$result[1]/spec-${result[2]}.jpg', '$result[2]')\">Click For Spec Image <img src="${img_url}specs/$result[1]/spec-${result[2]}.jpg" width=5 height=5></a><br><br>^;
                } elsif (-e "${home_dir}img/specs/$result[1]/spec-${result[2]}\.gif") {
                        print qq^&nbsp;&nbsp;&nbsp; <a href=\"javascript: productView('${img_url}specs/$result[1]/spec-${result[2]}.gif', '$result[2]')\">Click For Spec Image <img src="${img_url}specs/$result[1]/spec-${result[2]}.gif" width=5 height=5></a><br><br>^;
                }
                                
                if (-e "${home_dir}docs/specs/pdf/$result[1]/$result[2]\.pdf") {
                        print qq^<br><br><img src="${img_url}pdf.jpg">&nbsp;&nbsp; <a href="${base_url}/docs/specs/pdf/$result[1]/$result[2].pdf" target="_blank">SPECIFICATION PDF</a><br><br>^;
                }
                
 #GET AND PRINT RELATED ITEMS FOR THIS PRODUCT
                $ST_DB = $DB_edirect->prepare("SELECT a.acc_mid1, a.acc_did1, a.acc_gid1, p.detail_descp, p.size1, p.finish
                                                                FROM accessories a, products p
                                                                WHERE a.acc_mid2 = '$result[1]'
                                                                and a.acc_did2 = '$result[2]'
                                                                and a.acc_did1 = p.prod_id");
                $ST_DB->execute();
                print "<br><b><u>RELATED ITEMS</u></b><br>";
                if (my ($acc_mid, $acc_did, $acc_gid, $descp, $size, $finish) = $ST_DB->fetchrow_array()) {
                        
                        do {    
                                if ($acc_gid) {
                                         $descp .= ' - MULTIPLE OPTIONS';
                                } else {      
                                        if ($size ne '') {
                                                $descp .= ' - ' . $size;
                                        } elsif ($finish ne '') {
                                                $descp .= ' - ' . $finish;
                                        }   
                                }               
                                print qq^&nbsp;&nbsp;&nbsp;&nbsp;
                        <a href=\"${cgi_url}usastore.pl?a=di&pid=${acc_did}\">
                                                $descp</a><br>^;
                        } while (($acc_mid, $acc_did, $acc_gid, $descp, $size, $finish) = $ST_DB->fetchrow_array());        
                } elsif (my $coll_id = $DB_edirect->selectrow_array("SELECT coll_id FROM collection_items WHERE brand_id = '$result[1]' and prod_id = '$result[2]'")) {

                       if ($coll_id) {
                          print qq^<span style="padding:10px"><a href="usacollect.pl?st=2&bid=$result[1]&cid=$coll_id">MATCHING COLLECTION PIECES</a></span>^;
                       } else {
                    print "<i>( NONE )</I>";
                       }                                
                } else {
                        print "<i>( NONE )</I>";
                
                } 
                $ST_DB->finish();        
 # END RELATED ITEMS

                print qq^</td></tr>^;
                         
                if ($result[1] == 700) {
                    print qq^<br><div style="font-weight:bold;color:#D20000;font-size:10pt;text-align:center">
		TOP KNOBS REQUIRES A SIGNATURE FOR ALL DELIVERIES</div>^;
                }
                
                print qq^</td></tr>
                         <tr><td class=detail><div style="color:#CCC;margin-bottom:5px">REGULAR PRICE: \$$result[16] </div>
                          <b>YOUR PRICE:</b> \$$result[8] $result[9]
                         </td></tr>
                         <tr><td class=detail><form style="margin:0px" method=post action=${cgi_url}usastore.pl>
                                        <input type=hidden name=a value=cart_add><b>QTY:</b><input type=text name=$result[2]_qty value="1" size=4>
                         <input type=submit value=\"ADD TO CART\" class=formButton>

                         </td></tr>^;
 

                print qq^<tr><td class=small style="padding-top:5px">
                                        <font color=\"#CAAC02\" ><b>NOTES:<br>
                                        - Normally ships $ship_time</b>^; 
                                       
                if ($result[10] > 0) {
                    $result[14] *= 100;
                        print qq^<br><b>- $result[14]\% discount when you buy $result[10] or more!</b></font><br>
                                        </td></tr>^;
                }
                
                print qq^<tr><td class=detail><div style="color:firebrick;font-size:9pt;margin-top:5px;margin-bottom:10px;margin-left:50px"><span style="font-size:13pt;font-weight:bold">FREE</span>
                                     GROUND SHIPPING ON ORDERS OF \$199 OR MORE!<br>
                                     <span style="font-size:13pt;font-weight:bold">REDUCED</span> GROUND SHIPPING ON ORDERS OF \$100 TO \$199</div>
                     <!--                
                                    <div style="border:5px dotted green;padding:5px;margin:10px;text-align:center">
                      Hurry and order your hardware now before the annual price increases take effect!
                  </div> -->   ^;
                                        
        #GET AND PRINT RELATED ITEMS FOR THIS PRODUCT
#                $ST_DB = $DB_edirect->prepare("SELECT a.acc_mid1, a.acc_did1, pd.detail_descp
#                                                                FROM accessories a, products p
#                                                                WHERE a.acc_mid2 = '$result[1]'
#                                                                and a.acc_did2 = '$result[2]'
#                                                                and a.acc_did1 = p.prod_id");
#                $ST_DB->execute();
#                print "<br><b><u>RELATED ITEMS</u></b><br>";
#                if (my ($acc_mid, $acc_did, $descp) = $ST_DB->fetchrow_array()) {
#                        
#                        do {    
#                
#                        print qq^&nbsp;&nbsp;&nbsp;&nbsp;
#                <a href=\"${cgi_url}usastore.pl?a=di&pid=${acc_did}\">
#                                                $descp</a><br>^;
#                        } while (($acc_mid, $acc_did, $descp) = $ST_DB->fetchrow_array());                        
#                } else {
#                        print "<i>( NONE )</I>";
#                
#                }               
                        print qq^</td></tr></table></form><tr><td style="padding-top:20px">
                                &nbsp;
                                  </td></tr>
                                  <tr><td>
                                  <button class=formButton onClick="javascript:history.back()">&lt;&lt;
                                  PREVIOUS PAGE</button></td></tr>
                        
^;
                
        
        }
                                        
} 
########################### END SUB detail_item ###############################
###############################################################################

#################################################################################
######################### DISPLAY CATALOG PAGE SUBROUTINE #######################
sub cat_display_page() {
        my ($query, @count, $results, $first_item, $numRows);
        
        $query = @_[0];
         
  #COUNT TOTAL MATCHING RESULTS 
        $ST_DB = $DB_edirect->selectrow_array("$query");
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

  #IF THE COUNT OF ITEMS IS GREATER THAN 0 THEN DISPLAY 10 RESULTS      
        if ($count > 0) {
    
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
                        <table border=0 bordercolor=#000000 cellpadding=5 cellspacing=0 width=780>^;

                                           
              #RETRIEVE RESULTS FROM DB
                # DECLARE LOCAL VARIABLES FOR BINDING TO DB TABLE COLUMNS
                my ($bid, $brand, $model_num, $group_id, $prod_id, $descp, $size1, $size2, $finish, $unit, $price, $disc_qty, $disc_amt, $stock, $qoh, $ship_time);  
                $ST_DB2 = $DB2_edirect->prepare($query);
                $ST_DB2->execute;
                $ST_DB2->bind_columns(\$bid, \$brand, \$model_num, \$group_id, \$prod_id, \$descp, \$size1, \$size2, \$finish, \$unit, \$price, \$disc_qty, \$disc_amt, \$stock, \$qoh, \$ship_time);   

            for ($i=0; $i<$numRows; $i++) {

                print qq^ <tr>^;
                for ($n=0; $n<4; $n++) {
                        if ($ST_DB2->fetch()) {
                                print qq^<td width=185>
                                        <table border=1 bordercolor=#000000 cellpadding=3 cellspacing=0 width=100%>
                                        <tr><td style="text-align:center" colspan=2 height=100>^;
                                        
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
                                   if ($w > 100) {
                                       print qq^<a href="usastore.pl?a=di&pid=$prod_id">
                                                     <img src="${prod_image_url}" width=100 border=0></a>^;
                                   } else {
                                       print qq^<a href="usastore.pl?a=di&pid=$prod_id"><img src="${prod_image_url}" width=$w border=0></a>^;
                                   }
                               } elsif ($image_ratio < 1) {  
                                   if ($h > 100) {
                                       print qq^<a href="usastore.pl?a=di&pid=$prod_id">
                                          <img src="${prod_image_url}" height=100 border=0></a>^;
                                   } else {
                                       print qq^<a href="usastore.pl?a=di&pid=$prod_id"><img src="${prod_image_url}" height=$h border=0></a>^; 
                                   }
                               } else {  
                                   print qq^<a href="usastore.pl?a=di&pid=$prod_id"><img src="${prod_image_url}" width=100 border=0></a>^; 
                       
                               }     
                        
                        print qq^ </td></tr>
                                  <tr>    
                                  <td class=detailMfg bgcolor="#30507F" colspan=2 height=10>^;
                                  
                        if ($group_id ne '') {
                            print "$model_num";
                        } else {
                            print "$prod_id";
                        }
                        
                        print qq^
                                  </td>
                                  </tr> 
                                  <tr>
                                        <td class=small height=50><b>$descp</b></a></td><td class=small>^;
                                  
                                  
                         if ($group_id ne '') {
                             my ($size_count) = $DB_edirect->selectrow_array("SELECT count(DISTINCT size1) FROM products WHERE group_id = '$group_id'");
                             my ($finish_count) = $DB_edirect->selectrow_array("SELECT count(DISTINCT finish) FROM products WHERE group_id = '$group_id'");      
                             if ($size_count > 1) {                                                            
                                  print qq^<span style="font-size:7pt;font-weight:bold">
                                          <a href=\"${cgi_url}usastore.pl?a=di&pid=${prod_id}\">SELECT SIZE</a></span><br>^;
                             } else {
                                  print qq^$size1<br>^;
                             }
                             
                             print qq^</td></tr><tr><td colspan=2 style="text-align:center;padding-top:15px;padding-bottom:15px" class=small>^;
                             
                             if ($finish_count > 1) { 
                                print qq^<span style="font-size:9pt;font-weight:bold">
                                        <a href=\"${cgi_url}usastore.pl?a=di&pid=${prod_id}\">SELECT FINISH</a></span><br>^;
                             } else {
                                print qq^$finish<br>^;
                             }
                          } else {
                              $price = sprintf("%.2f", $price);
                              print qq^$size1</td></tr><tr><td class=small>
                                    $finish</td><td align=right class=small nowrap>            
                                        <b><font color="#FF8040">\$$price</font> $unit</b>
                                                </td></tr><form method=post action=usastore.pl>
                                              <input type=hidden name=a value=cart_add>
                                              <tr><td class=small height=20 nowrap>
                                              QTY: <input type=text name=${prod_id}_qty value="" size=3></td><td nowrap><input type=submit value=ADD class=formButton><a href=\"${cgi_url}usastore.pl?a=di&pid=${prod_id}\" style="padding-left:5px; font-weight:bold; font-size:8pt">VIEW</a>
                                              </td></tr>^;     
                          } 
                          

#                        if ($spid && $spid ne 'NEW') {
#                                my $specPrice = &calcSpecial("$spid", "$list");
#                                $list *= .75;   
#                                $list = sprintf("%.2f", $list);
#                                print qq^<td align=right class=small><b><font color=#FF8040>
#                                <strike>\$$list</font> $unit</strike></b>
#                                <b><font color="#EA0000">
#                                SPECIAL: \$$specPrice</font></b></td></tr>^;
#                        } else {
#                                $price = sprintf("%.2f", $price);
#                                print qq^<td align=right class=small nowrap>            
#                                        <b><font color="#FF8040">\$$price</font> $unit</b>
#                                                </td></tr>^;
#                        }       

                                                                      
                #IF A CASE QUANTITY EXISTS THEN PRINT THE QTY DISCOUNT MESSAGE  
                        if ($case > 0) {
                           if ($group_id ne '') {
                                print qq^<tr><td class=tiny colspan=2 height=15 align=center>
                                        <div style="color:#BF4451">
                                        QUANTITY DISCOUNTS AVAILABLE.  
                                        </div>
                                        </td></tr>^;
                           } else {
                                print qq^               
                                        <tr><td class=tiny colspan=2 height=15 align=center>
                                        <div style="color:#BF4451">
                                        DISCOUNT ON $disc_qty OR MORE.  
                                        </div>
                                        </td></tr>^;
                           }
                        } 
    
                
                                print qq^</table> </form>
                                        </td>^;

                        } else {
                                        last;
                                }# END MAIN IF          
                }  # END for LOOP THAT PRINTS EACH CELL
                        print "</tr>";
        } # END for LOOP THAT PRINTS EACH ROW
        
        print "</td></tr></table></td></tr><tr><td>";
        
        $ST_DB2->finish();
  
        if ($count > 20) {
            &page_continuation($count, $form{ind});
        }
        
        
        print "</td></tr>"
                        
  #IF THERE AREN'T ANY PRODUCTS TO DISPLAY                      
        } else {
                &cat_no_results();
        }

}
########################### END SUB display_page ##############################
###############################################################################

###############################################################################
####################### NO MATCHING RESULTS SUBROUTINE ########################
sub cat_no_results() {
        print qq^ <tr><td style="text-align:center">
                        <table cellpadding=20cellspacing=0 width=700>
                        
                        <tr><td>
<script language="javascript">
<!--
function SetSearchParam()
{
	document.form2.url.value = 'http://www.cooking.com/products/creative_redirect_CJ.asp?c=' + document.form2.c.value;
}
//-->
</script>

<TABLE WIDTH="150" HEIGHT="230" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#F3EBC7">
	<TR>
		<TD COLSPAN="3"><A href="http://www.jdoqocy.com/mh122ox52x4KNNUQNONKMLPMOUQT?url=http%3A%2F%2Fwww.cooking.com%2F"><IMG SRC="http://www.cooking.com/images/cj_creatives/150x230dropdown/cooking_01.gif" WIDTH="150" HEIGHT="69" BORDER="0"></A></TD>
	</TR>
	<form action="http://www.kqzyfj.com/interactive" onsubmit="SetSearchParam();" name="form2" method="get">
	<TR>
		<TD WIDTH="3" BACKGROUND="http://www.cooking.com/images/cj_creatives/150x230dropdown/cooking_02.jpg"><IMG SRC="http://www.cooking.com/images/cj_creatives/150x230dropdown/cooking_02.gif" WIDTH="3" HEIGHT="52"></TD>
		<TD WIDTH="144" ALIGN="CENTER">
		<TABLE WIDTH="134" BORDER="0" CELLPADDING="0" CELLSPACING="0">
			<TR>
				<TD WIDTH="134">
				<select name="c">
				<OPTION value=ba>Bakeware
				<OPTION value=br>Barware
				<OPTION value=clear>Clearance
				<OPTION value=sf>Coffee &amp; Tea
				<OPTION value=ct>Cook's Tools
				<OPTION value=books>Cookbooks
				<OPTION value=ck>Cookware
				<OPTION value=cu>Cutlery
				<OPTION value=fu>Furnishings
				<OPTION value=gift>Gift Baskets
				<OPTION value=food>Gourmet Foods
				<OPTION value=hc>Home Keeping
				<OPTION value=large>Large Appliances
				<OPTION value=oe>Outdoor Living
				<OPTION value=el>Small Appliances
				<OPTION value=so>Storage
				<OPTION value=tw>Tableware
				<OPTION value=vac>Vacuum Cleaners
				</select>
 				</TD>
			</TR>
			<TR>
				<TD WIDTH="144"><IMG SRC="http://www.cooking.com.edgesuite.net/images/transp.gif" WIDTH="134" HEIGHT="5"></TD>
			</TR>
			<TR>
				<TD WIDTH="144"><input type="image" src="http://www.cooking.com.edgesuite.net/images/newsletters/sbg.gif" width="40" height="15" border="0"></TD>
			</TR>
		</TABLE></TD>
		<TD WIDTH="3" BACKGROUND="http://www.cooking.com/images/cj_creatives/150x230dropdown/cooking_04.jpg"><IMG SRC="http://www.cooking.com/images/cj_creatives/150x230dropdown/cooking_04.gif" WIDTH="3" HEIGHT="52"></TD>
	</TR>
	
<input type="hidden" name="aid" value="10413958"/>
<input type="hidden" name="pid" value="2295232"/>
<input type="hidden" name="url" value="http://www.cooking.com/products/creative_redirect_CJ.asp?"/>
</form>
	<TR>
		<TD COLSPAN="3"><A href="http://www.jdoqocy.com/tn83iqzwqyDGGNJGHGDFEIFHNJM?url=http%3A%2F%2Fwww.cooking.com%2F"><IMG SRC="http://www.cooking.com/images/cj_creatives/150x230dropdown/cooking_05.gif" WIDTH="150" HEIGHT="109" BORDER="0"></A></TD>
	</TR>
</TABLE>
<img src="http://www.awltovhc.com/cg66bosgmk588FB898576A79FBE" width="1" height="1" border="0"/>
                        </td>
                        <td class=detail>
                        <p>I can't find any matches for what you entered.  If you are 
                        searching by item number; item numbers 
                                usually vary from seller to seller in some small way.  For 
                                instance, the Amerock part number 4425-RBZ translates to
                                A04425-RBZ in our database, but could be something else on 
                                another site or in a retail store such as BP4425-RBZ or 
                                AMBP4425-RBZ or CM4425-RBZ, I'm sure you get the picture.  
                          However, 
                                notice that the 4425-RBZ is the same in all four.  If you try
                                your search without the first character or two (or even just
                                the core number 4425), you may find     what you are looking for.</p>
                        <p>If you are searching on keyword terms or phrases, try using 
                        less words in the phrase or a variation on the term. </p> 
                        
                        <p>For an advanced detailed search, please use our 
                        <a href="usasearch.pl?st=1">Selective-Search</a> feature.</P>
                        
                        <p>If you are still getting this message and can't find what you are    
                        looking for, please 
                        <a href=\"mailto:service\@usacabinethardware.com?Subject=Search_Problems\">e-mail</a> 
                        us and we will get back to you in 24 to 48 hours.</p>
                        
                        Try <a href="${base_url}search.html">keyword search</a> again.

                        </td></tr>
                        </table>
                        </td></tr> ^;
}               
############################## END SUB no_results #############################
############################################################################### 

###############################################################################
######################## CATALOG search SUBROUTINE ############################
sub cat_search() {
    my ($cat_id_start, $cat_id_end) = ('3800', '3979');
    
    my $node_tree = &create_node_tree("$form{cnid}") if (exists($form{cnid}));
    
    $form{search_within} = $form{sw} if ($form{sw});
    $form{search_value} = $form{sv} if (exists($form{sv}));
    $form{o_search_value} = $form{search_value};

    if ($form{search_value} eq '') {
        print qq^ <tr><td style="padding-top:20px" style="text-align:center">
                  <table bgcolor=#C5CDE2 border=1 bordercolor=#000000 cellpadding=5 cellspacing=0 width=600>
                  
                  <tr><td style="text-align:center"><b>
                  <br><br>
                  PLEASE ENTER A VALUE TO SEARCH FOR!
                  <br><br>
                  <a href="${base_url}search.html">CLICK HERE</a> TO RETURN TO THE SEARCH PAGE
                  <br><br>
                  </td></tr>
                  </table>
                  </td></tr> ^;
            return;
    }


   #DECLARE VARIABLES FOR THIS SUBROUTINE       
    my ($brands, $search_query, $pre_search_query);
    
    my $prod_id_test = $DB_edirect->selectrow_array("SELECT prod_id FROM search_index
                            WHERE prod_id LIKE '%$form{search_value}%'");
                            
    if (defined($prod_id_test)) {
        $search_query = "SELECT SQL_CALC_FOUND_ROWS STRAIGHT_JOIN DISTINCT b.brand_id, b.brand, model_num, group_id, p.prod_id, 
                  detail_descp, size1, size2, finish, unit, price, disc_qty, 
                  disc_amt, stock, qty_oh, ship_time 
                  FROM prod_to_store pts, products p, brands b
                  WHERE pts.prod_id LIKE '%$form{search_value}%'
                  and p.prod_id = pts.prod_id 
                  and b.brand_id = p.brand_id
                  and status != 0";
                           
    } else {                               
        $search_query = "SELECT SQL_CALC_FOUND_ROWS DISTINCT b.brand_id, b.brand, model_num, group_id, 
                p.prod_id, detail_descp, size1, size2, finish, unit, price, 
                disc_qty, disc_amt, stock, qty_oh, ship_time 
                FROM brands b, products p, prod_to_store pts, search_index si
                WHERE p.brand_id = b.brand_id
                and pts.prod_id = p.prod_id
                and si.prod_id = pts.prod_id ";

       
        if ($searchBrandId ne '') {
                        $search_query .= " and b.brand_id = $searchBrandId'";

        }
              
# COMMENTED OUT 12/5/08                              
#        if (@$node_tree == 1) {
#            $cat_id_start = $DB_edirect->selectrow_array("SELECT min(aisle_id) FROM store_aisles sa
#                                WHERE sa.dept_id = d.dept_id
#                                and d.store_id = @$node_tree[0]->{node_id}");
#            $cat_id_end = $DB_edirect->selectrow_array("SELECT max(cat_id) FROM categories
#                                WHERE c.dept_id = d.dept_id
#                                and d.store_id = @$node_tree[0]->{node_id}");                 
#        } elsif (@$node_tree == 2)  {
#            $cat_id_start = $DB_edirect->selectrow_array("SELECT min(cat_id) FROM categories
#                                WHERE dept_id = @$node_tree[1]->{node_id}");
#            $cat_id_end = $DB_edirect->selectrow_array("SELECT max(cat_id) FROM categories
#                                WHERE dept_id = @$node_tree[1]->{node_id}");    
#        }  else {
#            $cat_id_start = @$node_tree[2]->{node_id};
#            $cat_id_end = @$node_tree[2]->{node_id};
#        }                    

        $search_query .= " and status != 0 ";

        $search_query .= " and MATCH (search_text) AGAINST ('$form{search_value}')";
    
                            
    }
 
 
    $search_query .= " GROUP BY group_id, model_num";
    
    if (exists($form{sortBy}) && $form{sortBy} ne '') {
        my ($field, $order) = split(/-/, $form{sortBy});
        $search_query .= " ORDER BY $field $order";
    } 
                 
    if ($form{ind} && $form{ind} != 0) {
            $search_query .= " LIMIT $form{ind}, 20";
            $form{ind} += 20;
    } else {
            $form{ind} = 20;
            $search_query .= " LIMIT 20";
    }

    
####INSERT SEARCH TERM INTO search_terms TABLE FOR SEARCH FEATURE TRACKING
        $form{search_within} = 'ALL' if (!$form{search_within});
        my $q_search_term = $DB_edirect->quote($form{search_value});
        
        $ST_DB = $DB_edirect->do("INSERT INTO search_terms(search_date, search_term, site_id, search_by)
                                        VALUES(NOW(), $q_search_term, $site_id, '$form{search_within}')");      
#########

#print "SEARCH VALUE: $form{search_value}<br>QUERY: $search_query<br>COUNT QUERY: $count_query";
        
        &cat_display_page("$search_query"); 

        
} 
############################### END SUB cat_search #############################
################################################################################        
