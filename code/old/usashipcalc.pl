#!/usr/bin/perl

# DATE: 2/12/03
# AUTH: JW Raugutt
# PROG: shipcalc.pl
# DESC: usacabinethardware.com shipping calculator
# Uses edirect shared MYSQL database.

# REVISIONS:

# call in DBI 
use DBI;
require qw(usalib.pl);

# call HTML form parsing subroutine
&parse();

# DECLARE GLOBAL VARIABLES
$img_url = 'http://www.usacabinethardware.com/img/';
$cgi_url = 'http://www.usacabinethardware.com/cgi-bin/';
$secure_cgi = 'https://secure.usacabinethardware.com/cgi-bin/';
$base_url = 'http://www.usacabinethardware.com/';
$secure_url = 'https://secure.usacabinethardware.com/';
$home_dir = '/vhosts/usacabinethardware.com/htdocs/';
#$home_dir = '/var/www/html/usa/';
$session_id = '';
$site_id = '4';
%ship_rates = (
        GROUND=>0,
        THREEDAY=>0,
        TWODAY=>0,
        NEXTDAY=>0
); 

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

########### CALCULATE SHIPPING FOR UPS METHODS
$ship_rates{GROUND} = &calc_shipping('GROUND');
        
$ship_rates{THREEDAY} = &calc_shipping('3DAY');
        
$ship_rates{TWODAY} = &calc_shipping('2DAY');

$ship_rates{NEXTDAY} = &calc_shipping('NEXTDAY');

&page_header();

&cart_display();
&page_footer();
&closeDBConnections();

exit;
###############################################################################
######################### DISPLAY CART SUBROUTINE #############################
sub cart_display() {

        # DECLARE AND INIT LOCAL VARIABLES
        my $sub_total = 0;
        my $display_type;
        
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
        
        foreach $key (%ship_rates) {
                if ($form{$key} == 0) {
                        $shipError = 1;
                        last;
                }
        }
        
        
        if (@$results != 0) {
        # PRINT CART CONTENTS   
                print qq^<TR><TD style="text-align:center"><br><br>
                                <TABLE bgcolor=\"#FFFFFF\" width=720 cellpadding=2 cellspacing=1 border=0><form method=post action=\"${cgi_url}usastore.pl\">
                                <input type=hidden name=a value=cart_add>
                                <input type=hidden name=recalc value=yes>^;
                                
                if (exists($form{display_items}) &&  $form{display_items} eq 'Y') {     
                print qq^      <TR>
                                <TD colspan=7 class=detail style="padding-top:20px">
                                <font size=\"3\"><b>Your Cart Contents</b></font>
                                </TD></TR>
                                <TR bgcolor=\"#C5CDEZ\">
                                <TH><font color=\"#FFFFFF\" size=2>QTY</font></TH>
                                <TH><font color=\"#FFFFFF\" size=2>PROD. ID</font></TH>
                                <TH><font color=\"#FFFFFF\" size=2>SIZE</font></TH>
                                <TH><font color=\"#FFFFFF\" size=2>DESCP</font></TH>
                                <TH><font color=\"#FFFFFF\" size=2>FINISH</font></TH>
                                <TH><font color=\"#FFFFFF\" size=2>PRICE</font></TH>
                                <TH><font color=\"#FFFFFF\" size=2>TOTAL</font></TH>
                                </TR> ^;
                } else {
                        print qq^<TR><TD colspan=7></TD></TR>^;
                }
                $qty_discount = 0;
                foreach $result (@$results) {
                        ($qty, $prod_id, $descp, $size, $finish, $price, $disc_qty, $disc_amt) = @$result;

                        if (($disc_qty != 0) && ($qty >= $disc_qty)) {
                                my $disc_ = &calcDiscount($qty, $price, $disc_amt);
                                $qty_discount += $disc_;
                        }
                                        
                        $price = sprintf("%.2f", $price);
                        my $prod_total = $qty * $price;
                        $prod_total = sprintf("%.2f", $prod_total);
                        $sub_total += $prod_total;
                
                        if (exists($form{display_items}) &&  $form{display_items} eq 'Y') {     
                        print qq^ <TR>
                                <TD class=detail><input type=text name=${prod_id}_qty value=\"$qty\" size=\"3\"> </TD>
                                <TD class=detail>${prod_id}</TD>
                                <TD class=detail>$size</TD>
                                <TD class=detail>$descp</TD><TD class=detail>$finish</TD>
                                <TD class=detail align=right>\$${price}</TD>
                                <TD class=detail align=right>\$${prod_total}</TD></TR>
                                <TR><TD colspan=7><hr noshade></TD></TR> ^;
                        }
                }

                $sub_total = sprintf("%.2f", $sub_total);               
                
                        print qq^<TR bgcolor="#C5CDE2"><TD colspan=4 class=detail>^;
                        
                if (exists($form{display_items}) &&  $form{display_items} eq 'Y') {     
                        print qq^<input class=formButton type=submit value=\"Recalculate\"></td></form>^;
                } else {
                        print qq^               
                                <SCRIPT>
                                <!--
                                document.write('<button class=formButton onClick=window.location="${cgi_url}usashipcalc.pl?display_items=Y&sid=${session_id}&cust_szip=$form{cust_szip}&cust_sctry=us">--v Display Cart Items</button>');
                                //-->
                                </SCRIPT>
                                <NOSCRIPT>
                                <a href="${cgi_url}usastore.pl?a=cart_display&sid=$form{sid}">
                                DISPLAY CART ITEMS</a></NOSCRIPT>
                                </td></form>^;
                }
                
                print qq^<TD colspan=2 align=right class=detail>
                                <b>ITEM TOTAL:</b></TD>
                                <TD class=norm style="text-align:right;font-size:11pt;font-weight:bold">\$${sub_total}</TD></TR>^;


                
        # PRINT CART SUMMARY LINES      
   
          # QUANTITY DISCOUNT           
                if ($qty_discount != 0 || $form{promo_code}) {
                  # IF PROMO CODE EXISTS, SET PROMO DISCOUNT 
                        if ($form{promo_code}) {
                                my @promo_info = $DB_edirect->selectrow_array("SELECT promo_name, 
                                                                  promo_type, promo_amount
                                                                  FROM promotions
                                                                  WHERE promo_id = '$form{promo_code}'");
                        
                                if ($promo_info[1] eq 'P') {
                                        $promo_discount = $sub_total * ($promo_info[2] / 100);
                                } else {
                                        $promo_discount = $promo_info[2];
                                }
                                                                
                                if ($form{promo_code} eq 'HFD13' && $sub_total < 75) {  
                                        $promo_discount = 0;
                                }
                                $qty_discount += $promo_discount;
                        }       
                        
                        $qty_discount = sprintf("%.2f", $qty_discount);
                        $sub_total -= $qty_discount;
                        print qq^<TR><TD colspan=6 style="color:#EE1100;font-weight:bold;font-size:11pt"><b>ORDER DISCOUNT:</b></TD>
                                    <TD style="color:#EE1100; font-weight:bold;font-size:11pt;text-align:right"> - \$${qty_discount}</TD></TR>^;
                        $form{qty_discount} = $qty_discount;
                }
                
          # SALES TAX FOR NORTH DAKOTA CUSTOMERS
                if ($form{cust_bstate} eq 'ND' && ($form{a} eq 'cart_summary' || $form{a} eq 'cart_submit')) {
                        $salesTax = &calc_salestax($sub_total);
                        $salesTax = sprintf("%.2f", $salesTax);
                        print qq^ <TR><TD colspan=6 align=right class=detail><b>ND SALES TAX:</b></TD>
                                <TD align=right class=detail>\$${salesTax}</TD></TR> 
                                <input type=hidden name=salestax value=\"$salesTax\">^;
                        $sub_total += $salesTax;
                        
                }

                print qq^ <tr><td colspan=7 align=right class=detail style="padding-top:10px">
                                  <form name=chkForm method=post action=usastore.pl>
                                  <input type=hidden name=a value=cart_checkout>
                                  <input type=hidden name=sTotal value=$sub_total>
                                  <input type=hidden name=ct value="">
                                  <input type=hidden name=totalSave value="">
                                  <input type=hidden name=GROUND value=$ship_rates{GROUND}>
                                  <input type=hidden name=THREEDAY value=$ship_rates{THREEDAY}>
                                  <input type=hidden name=TWODAY value=$ship_rates{TWODAY}>
                                  <input type=hidden name=NEXTDAY value=$ship_rates{NEXTDAY}>
                                  <table border=0 cellpadding=2 cellspacing=0 width=100%>
                                  <tr><td valign=top  style="text-align:right" rowspan=4>
                                  <img src="${img_url}select_ship.gif" width=240 height=96>
                                  </td>
                                  <td colspan=4 class=detail><b>GROUND</b></td>
                                        <td class=detail style="text-align:right">\$$ship_rates{GROUND}</td></tr>
                                        <tr>
                                        <td colspan=3 class=detail bgcolor=#C5CDE2>
                                        <b>3DAY SELECT</b></td>
                                        <td class=detail style="text-align:right" bgcolor=#C5CDE2>\$$ship_rates{THREEDAY}</td>
                                        <td class=trShipCalc></td></tr>
                                        <tr>
                                        <td colspan=2 class=detail><b>2ND DAY AIR</b></td>
                                        <td class=detail style="text-align:right">\$$ship_rates{TWODAY}</td>
                                        <td bgcolor=#C5CDE2></td>
                                        <td class=trShipCalc></td>
                                        </tr>
                                        <tr>
                                        </td>
                                        <td class=detail bgcolor=#C5CDE2><b>NEXTDAY AIR</b></td>
                                        <td class=detail style="text-align:right" bgcolor=#C5CDE2>\$$ship_rates{NEXTDAY}</td>
                                        <td class=trShipCalc></td>
                                        <td bgcolor=#C5CDE2></td>
                                        <td class=trShipCalc></td></tr>^;
                
                        
                $sub_total = sprintf("%.2f", $sub_total);       
                
        my ($groundTotal, $threeDayTotal, $twoDayTotal, $nextDayTotal);
        
        if ($ship_rates{GROUND} == 0) {
                $groundTotal = 'N/A';        
        } else {
                $groundTotal = sprintf("%.2f", $sub_total + $ship_rates{GROUND});
        }
        
        if ($ship_rates{THREEDAY} == 0) {
                $threeDayTotal = 'N/A';        
                } else {
                $threeDayTotal = sprintf("%.2f", $sub_total + $ship_rates{THREEDAY});   
        }
        
                $twoDayTotal = sprintf("%.2f", $sub_total + $ship_rates{TWODAY});       
                $nextDayTotal = sprintf("%.2f", $sub_total + $ship_rates{NEXTDAY});     
                
                print qq^<tr><td colspan=2></td>
                                <td colspan=4><hr size=1></hr></td>
                                </tr>
                                <tr>                    
                                <td colspan=2 class=detail bgcolor=#C5CDE2>
                                <b>ORDER TOTAL FOR EACH SHIPPING RATE:</b><br></TD>
                                <td class=detail style="text-align:right" bgcolor=#C5CDE2>
                               <b>\$$nextDayTotal</b></td>
                                <td class=trShipCalc style="text-align:right">
                                 <b>\$$twoDayTotal</b></td>
                                <td class=detail style="text-align:right" bgcolor=#C5CDE2>
                               
                                <b>\$$threeDayTotal</b></td>
                                <td class=trShipCalc style="text-align:right;font-size:12pt;font-weight:bold">
                                
                                 <b>\$$groundTotal</b></td>
                                </tr>
                                </table>

                                </TD></TR>^;    

                                
                print qq^
                                <TR><TD colspan=7><hr noshade></TD></TR>
                                <TR>
                                <TD colspan=7 align=left class=detail><br><br>
                                        <table border=0 cellpadding=0 cellspacing=0 width=100%>
                                        <tr><td align=left>
                                <img src="${img_url}select_checkout.gif" width=500 height=30>
                                        </td>
                                        <td>
                                        <a href="${secure_cgi}usastore.pl?a=cart_checkout&sid=$form{sid}">
                                        <img border=0 src="${img_url}place_order.jpg"></a>
                                        </td>
                                        </tr>
                                        <tr>
                                        <td align=center valign=top>
                                              
                                        </td>
                                        <td align=center valign=top>
<script type="text/javascript">TrustLogo("http://www.usacabinethardware.com/img/qssl_trustlogo.gif", "QLSSL", "none");
</script>               
<noscript><img src="${img_url}img/qsslnojs_90.gif" width="90"></noscript>
<br>                                                            
                                        </td>
                                        </tr>
                                        </table>
                                </TD></TR>
                                </form>
                                <TR><TD colspan=7><hr noshade></TD></TR>
                                <TR><TD colspan=7>
                                <img src=\"${img_url}space.gif\" width=400 height=10>
                                </TD></TR>
                                </table>
                                </TR></TR>
                                
                                <TR><TD colspan=2 align=right>
                                        <table width=100% border=0 cellpadding=2 cellspacing=0>
                                        <tr><td>
                                <a href=\"${cgi_url}usastore.pl?a=cart_clear&sid=${session_id}\">
                                Clear Cart</a></td>
                                        <td align=center>
                                <a href=\"javascript:history.back(2)\">
                                Continue Shopping</a></td>
                                        <td align=right>
                                <a href=\"${secure_cgi}usastore.pl?a=cart_checkout&sid=${session_id}\">
                                Check Out</a></td></tr>
                                        </table>
                                </TD></TR>
                                ^;
                                
### CUT CALCULATE SHIPPING CODE 2/12/03
                                
        } else {
                &cart_empty();  
        }
} 
############################### END DISPLAY_CART SUB ##########################                                                  
###############################################################################

###############################################################################
######################## CART_DISPLAY_ERROR SUBROUTINE ########################
sub cart_display_error() {

        # DECLARE AND INIT LOCAL VARIABLES
        my $sub_total = 0;
        my $display_type;

        
        if (@_) {
                $display_type = $_[0];
        } else {
                $display_type = '';
        }

        # PREPARE SQL FOR EXECUTION
        $ST_DB = $DB_edirect->prepare("SELECT c.qty, c.mfg_id, c.detail_id, pd.detail_descp, pd.size1, pd.finish, pd.list, pd.case_qty, pd.case_list 
                                            FROM cart c, product_details pd 
                                            WHERE c.session_id = '$session_id'
                                                and c.site_id = '$site_id'
                                            and c.detail_id = pd.detail_id
                                                and c.mfg_id = pd.mfg_id");
        # EXECUTE SQL           
        $ST_DB->execute();
        $results = $ST_DB->fetchall_arrayref();
        $ST_DB->finish();
                
        
        if (@$results != 0) {
        # PRINT CART CONTENTS   
                print qq^<TR><TD align=center class=detail><br>
                                <font color="#E10000"><b>AN ERROR PREVENTED YOUR SHIPPING FROM BEING CALCULATED. TO TRY CALCULATING YOUR SHIPPING AGAIN, ENTER YOUR ZIP CODE.</b></font></TD></TR>
<TR><TD align=center style="padding-top:15px">
                        <table border=0 cellpadding=0 cellspacing=0><tr><td valign=top>
                        <form method=post action=\"${cgi_url}usashipcalc.pl\">
                        <input type=hidden name=cust_sctry value=us>
                        <input type=hidden name=sid value=$session_id>
                        <table border=0 cellpadding=3 cellspacing=0>
                        <tr>
                        <td>    
                                <table border=1 bordercolor=#000000 width=190 cellpadding=5 
                                cellspacing=0 align=left>
                                <tr>
                                <td bgcolor=\"#30507F\" align=center>
                                <font color=\"#FFFFFF\" size=2> 
                                <b>SHIPPING CALCULATOR</b></font></td></tr>
                                
                                <tr><td class=small><b>ALL 50 U.S. STATES:</b><br>
                                Enter your zip code and click the 
                                CALCULATE button. Your shipping will be
                                calculated and displayed for you, allowing you to make
                                an informed decision before you begin the checkout 
                                process.<br><br>
                                <b>ALASKA & HAWAII:</b><br>
                                <a href="${base_url}policies.html#shipping">Click here</a>
                                for more shipping information.</td></tr>
                                <tr><td align="center" class=small>Enter Zip Code:
                                <input type=text 
                                name=cust_szip value=\"\" size=5></td></tr>
                                <tr><td align="center"><input class=formButton type=submit
                                value=\"CALCULATE\"></td></tr>
                                </table>
                        </td></tr>
                        <tr><td align=center>
                                <!--
BEGIN QUALITYSSL REALTIME SEAL CODE 1.0
Shows the seal graphic from URL http://www.usacabinethardware.com/img/qssl_90.gif
The seal graphic is Not Floating
//-->
<script type="text/javascript">TrustLogo("http://www.usacabinethardware.com/img/qssl_trustlogo.gif", "QLSSL", "none");
</script>               
<noscript><img src="${img_url}img/qsslnojs_90.gif" width="90"></noscript>
 
                        </td></tr>
                        </table>
                   </form>
                   </td><td valign=top>^;
 
                
                print qq^<table border=0 width=100% cellpadding=2 cellspacing=1>^;
                
                if ($form{sa} ne 'cart_summary' && $form{a} ne 'cart_submit') {
                        print qq^ 
                                <form method=post action=\"${cgi_url}usastore.pl\">
                                <input type=hidden name=a value=cart_add>
                                <input type=hidden name=recalc value=yes>
                        <TR>
                                <TD colspan=7 class=detail>
                                <font size=\"3\"><b>Your Cart Contents</b></font><br>
                                To change quantities, change the number (or to remove an item
                                , enter <b>0</b>) in the quantity box and click the 
                                <b>\"Recalculate\"</b> button in the lower left.  To completely 
                                remove all of the items from your cart, click the 
                                <b>\"Clear Cart\"</b> link. To continue shopping, click the 
                                <b>\"Continue Shopping\"</b> link. If you 
                                 are ready to checkout, click the <b>\"Checkout\"</b> link.
                                </TD></TR>^;
                }
                
                print qq^
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
                
                $qty_discount = 0;
                foreach $result (@$results) {
                        ($qty, $prod_id, $descp, $size, $finish, $price, $disc_qty, $disc_amt) = @$result;

                        if (($disc_qty != 0) && ($qty >= $disc_qty)) {
                                my $disc_ = &calcDiscount($qty, $price, $disc_amt);
                                $qty_discount += $disc_;
                        }
                                        
                        $price = sprintf("%.2f", $price);
                        my $prod_total = $qty * $price;
                        $prod_total = sprintf("%.2f", $prod_total);
                        $sub_total += $prod_total;
                        print qq^ <TR>
                                <TD class=detail>^;
                                
                        if ($form{sa} ne 'cart_summary' && $form{sa} ne 'cart_submit') {
                                print qq^<input type=text name=${prod_id}_qty value=\"$qty\" size=\"3\"> ^;
                        } else {
                                print "$qty";
                        }
                                
                        print qq^ </TD>
                                <TD class=detail>${detail_id}</TD><TD class=detail>$size</TD>
                                <TD class=detail>$descp</TD><TD class=detail>$finish</TD>
                                <TD class=detail align=right>\$${price}</TD>
                                <TD class=detail align=right>\$${prod_total}</TD></TR>
                                <TR><TD colspan=7><hr noshade></TD></TR> ^;
                }

                $sub_total = sprintf("%.2f", $sub_total);               
                
                if ($form{sa} ne 'cart_summary' && $form{sa} ne 'cart_submit') {
                        print qq^<TR><TD colspan=2 class=detail>
                                <input class=formButton type=submit value=\"Recalculate\"></td></form>
                                <TD colspan=2 align=center valign=top>
                                
                                </TD> 
                                <TD colspan=2 align=right class=detail>
                                <b>SUB TOTAL:</b></TD>
                                <TD align=right class=detail>\$${sub_total}</TD></TR>^;
                } else {
                        print qq^<TR>
                                <TD colspan=6 align=right class=detail>
                                <b>SUB TOTAL:</b></TD>
                                <TD align=right class=detail>\$${sub_total}</TD></TR>^;
                }

                
        # PRINT CART SUMMARY LINES      
                
          # QUANTITY DISCOUNT           
                if ($qty_discount != 0 || $form{promo_code}) {
                        $qty_discount *= .75 if ($qty_discount);
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
                                $qty_discount += $promo_discount;
                        }       
                        
                        $qty_discount = sprintf("%.2f", $qty_discount);
                        $sub_total -= $qty_discount;
                        print qq^<TR><TD colspan=6 align=right class=detail><b>ORDER DISCOUNT:</b></TD>
                                                <TD align=right class=detail> - \$${qty_discount}</TD></TR>^;
                        $form{qty_discount} = $qty_discount;
                }
                
          # SALES TAX FOR MINNESOTA CUSTOMERS
                if ($form{cust_bstate} eq 'ND' && ($form{sa} eq 'cart_summary' || $form{sa} eq 'cart_submit')) {
                        $salesTax = &calc_salestax($sub_total);
                        $salesTax = sprintf("%.2f", $salesTax);
                        print qq^ <TR><TD colspan=6 align=right class=detail><b>ND SALES TAX:</b></TD>
                                <TD align=right class=detail>\$${salesTax}</TD></TR> 
                                <input type=hidden name=salestax value=\"$salesTax\">^;
                        $sub_total += $salesTax;
                        
                }

     # PRINT SHIPPING IF SHIPPING METHOD HAS BEEN SELECTED
                if ($display_type eq 'shipping') {
#                       if ($sub_total >= 150 && $form{ord_ship_method} eq 'GROUND') {
#                               $ship_cost = 0;
#                               $form{ship_cost} = 0;
#                       }
                        $sub_total += $form{ship_total};
                        print qq^ <tr><td colspan=6 align=right class=detail>
                                <b>SHIPPING: <i>($form{ord_ship_method})</i></b></td>
                                        <td align=right class=detail>\$$form{ship_total}</td></tr> ^;
                }       
   
                                
                $sub_total = sprintf("%.2f", $sub_total);       
                
                if ($form{sa} ne 'cart_summary' && $form{sa} ne 'cart_submit') {
                        print qq^ <TR><TD colspan=6 align=right class=detail>
                                <b>CART TOTAL:</b></TD>
                                <TD align=right class=detail>\$${sub_total}</TD></TR></form> ^;
                } else {
                        print qq^ <TR><TD colspan=6 align=right class=detail>
                                <b>ORDER TOTAL:</b></TD>
                                <TD align=right class=detail>\$${sub_total}</TD></TR> ^;        
                }                       

                $form{ord_total} = $sub_total;
                                
                if ($form{sa} ne 'cart_summary' && $form{sa} ne 'cart_submit') {
                        print qq^
                                <TR><TD colspan=7><hr noshade></TD></TR>
                                <TR><TD colspan=2 align=right>
                                <a href=\"${cgi_url}usastore.pl?a=cart_clear&sid=${session_id}\">
                                Clear Cart</a></TD>
                                <TD colspan=3 align=center>
                                <a href=\"javascript:history.back()\">
                                Continue Shopping</a></TD>
                                <TD colspan=2 align=center>
                                <a href=\"${secure_cgi}usastore.pl?a=cart_checkout&sid=${session_id}\">
                                Check Out</a></TD></TR>
</td>
</tr>
</table>^;
                }
                
                print qq^<TR><TD colspan=7>
                                <img src=\"${img_url}space.gif\" width=400 height=10>
                                </TD></TR>                      
                                </table>
                                </TD></TR> ^;
                                
        } else {
                &cart_empty();  
        }
} 
######################### END CART_DISPLAY_ERROR SUB ##########################                        
###############################################################################
        
###############################################################################
############################ EMPTY CART SUBROUTINE ############################ 
sub cart_empty() {
        print qq^<TR><TD colspan=2 align=center>
                <table width=600>
                <tr><td align=center><br><br><br><font size=4>
                Your cart is currently empty.  To add
                items to your cart, simply indicate the quantity you'd like
                and click the \"Add\" button.<br><br></td></tr>
                </table>
        <TD></TR> ^;
}
################################# END EMPTY CART SUB ########################## 
###############################################################################                                                                                                                                  
