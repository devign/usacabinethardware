#!/usr/bin/perl

# DATE: 4/22/03
# AUTH: J.W. Raugutt
# PROG: usamailorder.pl
# DESC: usacabinethardware.com printable order form program
# Uses edirect shared MYSQL database.

# REVISIONS:

# call in DBI 
use DBI;
require qw(usalib.pl);

# call HTML form parsing subroutine
&parse();

# DECLARE GLOBAL VARIABLES
$img_url = 'https://secure.usacabinethardware.com/img/';
$cgi_url = 'http://www.usacabinethardware.com/cgi-bin/';
$secure_cgi = 'https://secure.usacabinethardware.com/cgi-bin/';
$base_url = 'http://www.usacabinethardware.com/';
$secure_url = 'https://secure.usacabinethardware.com/';
$home_dir = '/vhosts/usacabinethardware.com/htdocs/';
#$home_dir = '/var/www/html/usa/';
$session_id = '';
$site_id = '4';

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

if (!$form{st} || $form{st} == 1) {
        &page_header();
        &display_input_form();
        &page_footer();
} elsif ($form{st} == 2) {
        &page_header();
        &order_summary();
        &page_footer();
} else {
        &fax_mail_order();
}

&closeDBConnections();

exit;

###############################################################################
######################### CART DISPLAY SUBROUTINE #############################
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
                
                print qq^<table border=0 width=100% cellpadding=2 cellspacing=1>
                                <TR>
                                <TD colspan=7 style="padding-top:20px">
                                
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

                        if (($case_qty != 0) && ($qty >= $case_qty)) {
                                my $disc_ = &calcDiscount($qty, $price, $disc_amt);
                                $qty_discount += $disc_;
                        }
                                        
                        $price = sprintf("%.2f", $price);
                        my $prod_total = $qty * $price;
                        $prod_total = sprintf("%.2f", $prod_total);
                        $sub_total += $prod_total;
                        print qq^ <TR>
                                <TD class=detail>$qty</TD>
                                <TD class=detail>${prod_id}</TD><TD class=detail>$size</TD>
                                <TD class=detail>$descp</TD><TD class=detail>$finish</TD>
                                <TD class=detail align=right>\$${price}</TD>
                                <TD class=detail align=right>\$${prod_total}</TD></TR>
                                <TR><TD colspan=7><hr noshade></TD></TR> ^;
                }

                $sub_total = sprintf("%.2f", $sub_total);               
                
                print qq^<TR>
                                <TD colspan=6 align=right class=detail>
                                <b>SUB TOTAL:</b></TD>
                                <TD align=right class=detail>\$${sub_total}</TD></TR>^;
                

                
        # PRINT CART SUMMARY LINES      
          
                
          # QUANTITY DISCOUNT           
                if ($qty_discount != 0 || $form{promo_code}) {
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
                                                                
                                if ($form{promo_code} eq 'HFD13' && $sub_total < 75) {  
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
                
          # SALES TAX FOR NORTH DAKOTA CUSTOMERS
                if ($form{cust_bstate} eq 'ND') {
                        $salesTax = &calc_salestax($sub_total);
                        $salesTax = sprintf("%.2f", $salesTax);
                        print qq^ <TR><TD colspan=6 align=right class=detail><b>ND SALES TAX:</b></TD>
                                <TD align=right class=detail>\$${salesTax}</TD></TR> 
                                <input type=hidden name=salestax value=\"$salesTax\">^;
                        $sub_total += $salesTax;
                        
                }

     # PRINT SHIPPING IF SHIPPING METHOD HAS BEEN SELECTED
                if ($display_type eq 'shipping') {
                       if ($sub_total >= 200 && $form{ord_ship_method} eq 'GROUND') {
                               $ship_cost = 0;
                               $form{ship_cost} = 0;
                       }
                        $sub_total += $form{ship_total};
                        print qq^ <tr><td colspan=6 align=right class=detail>
                                <b>SHIPPING: <i>($form{ord_ship_method})</i></b></td>
                                        <td align=right class=detail>\$$form{ship_total}</td></tr> ^;
                }       

         # PRINT HANDLING FEE IF NOT ZERO
                if ($form{handling} != 0) {
                        $sub_total += $form{handling};
                        $form{handling} = sprintf("%.2f", $form{handling});
                        print qq^ <TR><TD colspan=6 align=right class=detail>
                        <b>HANDLING FEE:</b></TD>
                                <TD align=right class=detail>\$$form{handling}</TD></TR> ^ ;
                }               
                                
                $sub_total = sprintf("%.2f", $sub_total);       
                $form{ord_total} = $sub_total;
                                
                print qq^ <TR><TD colspan=6 align=right class=detail>
                                <b>ORDER TOTAL:</b></TD>
                                <TD align=right class=detail>\$${sub_total}</TD></TR></table>
                                </TD></TR>  ^;  

        } else {
                &cart_empty();  
        }
} 
############################### END cart_display SUB ##########################
###############################################################################

###############################################################################
####################### DISPLAY ORDER INPUT FORM SUBROUTINE ###################
sub display_input_form() {
        print qq^<TR><TD><h2 class=top>CHECKOUT->FAX/MAIL ORDER INPUT</h2></TD></TR>
                 <TR><form name="mailOrderForm" method=post action="${secure_cgi}usamailorder.pl" onSubmit="return validateBilling(this)">
                <input type=hidden name=st value=2>
                <input type=hidden name=sid value=$session_id>
                        <td align=center>
                <table width=680 bgcolor=#C5CDEZ bordercolor=black cellpadding=2 cellspacing=0 border=1>
                <tr>
            <td class=detail valign=top>
                        <table bgcolor=#FFFFFF border=0 cellpadding=5 cellspacing=0>
                        <tr><td class=detail>
                        <b>INSTRUCTIONS:</b><br>
                        Fill out the form completely. All fields labeled in 
                        <font class=reqd>red</font> are 
                        required fields.  The required <b>"SHIPPING INFORMATION"</b> fields 
                        are only required if you uncheck the box labeled<b>"SAME AS ABOVE 
                        INFORMATION"</b> 
                        and want your order shipped to a name and/or address different
                        from the <b>"CUSTOMER INFORMATION"</b>.  If you want your order shipped to the same
                        address, simply leave the checkmark in the checkbox next to 
                        <b>"SAME AS ABOVE 
                        INFORMATION"</b> and don't fill-out any of the shipping fields.
                        <br><br>
                        Select a shipping method and add any order or 
                        shipping comments.  After you have completed all the necessary
                        fields, click the <b>CONTINUE >></b> button.  The next screen will
                        show you a summary of your order including all the information
                        from this screen as well as the items on your order, the shipping
                        amount, applicable sales tax and an order grand total.
                        </td>
                        </tr>
                        </table>
                </td>
                <td valign=top>
                        <table width=480 border=0 cellspacing=0 cellpadding=2>
                        <tr>
                        <td colspan=3 class=detailB>CUSTOMER INFORMATION
                        <hr></hr></td>
                        </tr>
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
<td class=reqd>Address 1:<br>
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
</select></td>
<td class=reqd>Zip Code:<br>
<input type=text name=cust_bzip  size=10></td>
</tr>
<input type=hidden name=cust_bctry value=us></td>

<tr>
<td class=reqd>E-mail:<br>
<input type=text name=cust_email size=30 onBlur="validateEmail(this, this.value)"></td>
<td class=reqd colspan=2>Phone:<br>
<input type=text name=cust_phone  size=30></td>
</tr>
        </table>
        <br><br>
        <table width=480 border=0 cellspacing=0 cellpadding=2>
        <tr>
        <td class=detailB>SHIPPING INFORMATION</td>
        <td class=detailB colspan=2>
<input type=checkbox name=ship_same value=Y checked>SAME AS ABOVE INFORMATION
        </td>
        </tr>
        <tr><td colspan=3><hr></hr></td></tr>
        
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
<td class=reqd>Address 1:<br>
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
</select></td>
<td class=reqd>Zip Code:<br>
<input type=text name=cust_szip  size=10></td>
</tr>
<input type=hidden name=cust_sctry value=us></td>
</tr>
                   </table>
        <br><br>
        <table width=480 border=0 cellspacing=0 cellpadding=2>
        <tr>
        <td class=detailB colspan=3>SHIPPING METHOD<hr></hr></td>
        </tr>
        <tr><td colspan=3 class=detailB>
        SELECT ONE:<br>
<select name=ord_ship_method>
<OPTION  VALUE="GROUND">GROUND</option>
<OPTION  VALUE="3DAY">UPS 3 DAY SELECT</option>
<OPTION  VALUE="2DAY">2ND DAY AIR</option>
<OPTION  VALUE="NEXTDAY">NEXTDAY AIR</option></select>
                <br><br>
                                ORDER/SHIPPING NOTES:<br>
                                <textarea name=ord_ship_struct rows=5 cols=30></textarea>
        </td>
        </tr>
        </table>
        
                           
                </td>
                </tr>
                </table>

</TD></TR>
<TR><TD align=center style="padding-top:15px">

<input type=submit name=continue value="CONTINUE >>" class=formButton></TD></TR> ^;             
}
##################### END DISPLAY ORDER INPUT FORM SUBROUTINE #################
############################################################################### 

###############################################################################
################### DISPLAY PRINTABLE ORDER FORM SUBROUTINE ###################
sub fax_mail_order() {
        print "Content-type:text/html\n\n";
        
print qq^ <html><head>
        <style>
        .detail {
        font-size: 10pt
        }
        </style>
        </head>
         <body bgcolor=#FFFFFF>
         <table border=0 cellpadding=5 cellspacing=0 width=640>
        <tr><td colspan=2>
        <h2>USACabinetHardware.com Order Form</h2>
        <hr></hr>
        </td></tr>
        <TR><td width=50\% valign=top class=detail><b>BILLING:</b><br>^;
print "$form{cust_company}<br>" if ($form{cust_company});
        
print qq^ $form{cust_bfname} $form{cust_blname}<br>
                $form{cust_badd1}<br>^;

if ($form{cust_badd2}) {
        print qq^$form{cust_badd2}<br>^;
}
print qq^
                $form{cust_bcity}, $form{cust_bstate} $form{cust_bzip}<br>
                $form{cust_phone}<br>
                $form{cust_email}
                </td>
                <td valign=top class=detail><b>SHIPPING:</b><br>^;
                
print "$form{cust_scompany}<br>" if ($form{cust_scompany});

print qq^$form{cust_sfname} $form{cust_slname}<br>
                $form{cust_sadd1}<br> ^;
                
if ($form{cust_sadd2}) {
        print qq^$form{cust_sadd2}<br>^;
}
print qq^
        $form{cust_scity}, $form{cust_sstate} $form{cust_szip}
                </td></tr>
                <tr><td colspan=2 valign=top> ^;        

&calc_shipping("$form{ord_ship_method}");

&cart_display('shipping');

print qq^</td></tr>
                 <tr><td colspan=2 class=detail>
                 PAYMENT: __VISA &nbsp;&nbsp;__MASTERCARD &nbsp;&nbsp;__DISCOVER&nbsp;&nbsp;__AMEX
                                &nbsp;&nbsp;__CHECK/MONEY ORDER<br><br>
                                CARDHOLDERS NAME: __________________________________________<BR><BR>
                                CARD #: _________________________________________________<BR><BR>
                                CCV (3 digit code in signature area on back of Visa, MC & Discover, 3 or 4 digit
                                code printed on front of Amex:<br><br>
                                __________________________<BR><BR>
                                EXP. DATE: _______________<br><br></td></tr>^;
                                
                                
        print qq^<tr>
                        <td colspan=2 class=detail>Please print, complete and fax this form to <b>701.281.0906</b>
                        </td></tr>
                        <tr>
                        <td colspan=2 class=detail>Or if you prefer, complete and mail this form to:<br><br>
                        USACabinetHardware.com<br>
                        Everything Direct<br>
                        1046 39th Ave W<br>
                        West Fargo, ND 58078 <br><br>
                        PLEASE MAKE CHECKS PAYABLE TO <b>EVERYTHING DIRECT</b><br><br>
                        <b>PLEASE NOTE: Check payments require up to 7 days to process AFTER we receive and enter your order.</b>
                        </td></tr>
                        <tr><td colspan="2" class="small">
                        <p>When you provide a check as payment, you authorize us either to use information from your check to make a one-time electronic fund transfer <p>from your account or to process the payment as a check transaction. For inquiries, please call 701.281.7905.</p>
When we use information from your check to make an electronic fund transfer, funds may be withdrawn from your account as soon as the same day you make your payment, and you will not receive your check back from your financial institution.</p>
                        </td>
                        </tr>
                        <tr><td colspan=2 style="padding-top:20px">
                        <a href="${base_url}">HOME PAGE</a>
                        </td></tr>
 ^;

}
########################### END SUB FAX_MAIL_ORDER ############################
###############################################################################

###############################################################################
############################## ORDER SUMMARY SUB ##############################
sub order_summary() {
        
    $form{cust_company} = uc $form{cust_company} if ($form{cust_company});
    $form{cust_bfname} = uc $form{cust_bfname};
    $form{cust_blname} = uc $form{cust_blname};
    $form{cust_badd1} = uc $form{cust_badd1};
    if ($form{cust_badd2}) {
        $form{cust_badd2} = uc $form{cust_badd2};
    }
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

        &calc_shipping("$form{ord_ship_method}");
        
                
        print qq^<form method=post action=${secure_cgi}usamailorder.pl onSubmit="this.btnOrdSubmit.value='PROCESSING...';this.btnOrdSubmit.disabled=true"> 
                <input type=hidden name=st value=fax_mail_order>        
                <input type=hidden name=sid value=$session_id>  
                ^;
        
  #PRINT CUSTOMER INFO
        print qq^ <TR><TD><H2 class=top>CHECKOUT->ORDER SUMMARY</H2></TD></TR>
                        
                        <TR><TD align=center>
                        <table width=620 cellpadding=5 cellspacing=0 border=1 bordercolor=\"#000000\">
                        <tr>
                        <td class=detail valign=top><b>SOLD TO:</b><br>^;
        
        print "$form{cust_company}<br>" if ($form{cust_company});
        
        print qq^               
                $form{cust_bfname} $form{cust_blname}<br>
                $form{cust_badd1}<br> ^;

        if ($form{cust_badd2}) {
                #print "$form{cust_badd2}<br>";
        }
        print qq^ $form{cust_bcity}, $form{cust_bstate} $form{cust_bzip}<br>
                $form{cust_email}<br><br>
        </td><td class=detail valign=top><b>SHIP TO:</b><br>^;
        print "$form{cust_scompany}<br>" if ($form{cust_scompany});
        print qq^$form{cust_sfname} $form{cust_slname}<br>
                        $form{cust_sadd1}<br>^;
        print "$form{cust_sadd2}" if ($form{sadd2});
        print qq^$form{cust_scity}, $form{cust_sstate} 
        $form{cust_szip}<br><br><b>SHIP METHOD:</b> $form{ord_ship_method}      
        </td></tr><tr><td valign=top colspan=2>^;
                        
        &cart_display('shipping');

        print qq^       </td></tr>
                        </table>
                    </TD></TR>

                    <TR><TD colspan=2 align=center> ^;
                
        foreach $key (sort keys %form) {
                if ($key =~ m/^cust_/) {
                        print "<input type=hidden name=$key value=\"$form{$key}\">\n";
                }
        }


        print qq^ <input type=hidden name=ord_pay_method value=\"$form{ord_pay_method}\">
                        <input type=hidden name=ord_ship_method value=\"$form{ord_ship_method}\">
                        <input type=hidden name=qty_discount value=\"$form{qty_discount}\">
                        <input type=hidden name=ord_total value=\"$form{ord_total}\">
                        <input type=hidden name=ord_ship_struct value=\"$form{ord_ship_struct}\">
                        <input type=hidden name=handling value=\"$form{handling}\">
<br><font size=3 color=\"#BF4451\">
                        <b>If your order is correct, press this button to generate a 
                        printable order form. If you 
                        need to change something, use your browser's \"Back\" button to go back and
                        make your changes.<br><br>
                        
                        </b></font><br>
                                <input name=btnOrdSubmit type=submit value=\"GENERATE PAGE\"></form> ^;                          
                                
        

} 
########################## END SUB order_summary ###############################
################################################################################



