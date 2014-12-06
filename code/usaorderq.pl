#!/usr/bin/perl

# DATE: 4/22/03
# AUTH: J.W. Raugutt
# PROG: usaorderq.pl
# DESC: usacabinethardware.com order quote program for customers in AL, HI
# and other countries
# Uses kituninc shared MYSQL database.

# REVISIONS:

# call in DBI 
use DBI;

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
$mail = '|/usr/sbin/sendmail -t';
$aff_id = '4';
#LOAD COUNTRIES HASH
%countries = (
us=>'United States',
al=>Albania,
dz=>Algeria,
as=>'American Samoa',
ad=>'Andorra, Principality of',
ao=>Angola,
ai=>Anguilla,
aq=>Antarctica,
ag=>'Antigua and Barbuda',
ar=>Argentina,
am=>Armenia,
aw=>Aruba,
au=>Australia,
at=>Austria,
az=>Azerbaidjan,
bs=>Bahamas,
bh=>Bahrain,
bd=>Bangladesh,
bb=>Barbados,
by=>Belarus,
be=>Belgium,
bz=>Belize,
bj=>Benin,
bm=>Bermuda,
bt=>Bhutan,
bo=>Bolivia,
ba=>'Bosnia-Herzegovina',
bw=>Botswana,
bv=>'Bouvet Island',
br=>Brazil,
io=>'British Indian Ocean Territory',
bn=>'Brunei Darussalam',
bg=>Bulgaria,
bf=>'Burkina Faso',
bi=>Burundi,
kh=>'Cambodia, Kingdom of',
cm=>'Cameroon',
ca=>'Canada',
cv=>'Cape Verde',
ky=>'Cayman Islands',
cf=>'Central African Republic',
td=>Chad,
cl=>Chile,
cn=>China,
cx=>'Christmas Island',
cc=>'Cocos (Keeling) Islands',
co=>Colombia,
km=>Comoros,
cg=>Congo,
cd=>'Congo, The Democratic Republic of the',
ck=>'Cook Islands',
cr=>'Costa Rica',
hr=>Croatia,
cy=>Cyprus,
cz=>'Czech Republic',
dk=>Denmark,
dj=>Djibouti,
dm=>Dominica,
do=>'Dominican Republic',
tp=>'East Timor',
ec=>Ecuador,
eg=>Egypt,
sv=>'El Salvador',
gq=>'Equatorial Guinea',
er=>Eritrea,
ee=>Estonia,
et=>Ethiopia,
fk=>'Falkland Islands',
fo=>'Faroe Islands',
fj=>Fiji,
fi=>Finland,
cs=>'Former Czechoslovakia',
su=>'Former USSR',
fx=>'France (European Territory)',
fr=>France,
gf=>'French Guyana',
tf=>'French Southern Territories',
ga=>'Gabon',
gm=>'Gambia',
ge=>Georgia,
de=>Germany,
gh=>Ghana,
gi=>Gibraltar,
gb=>'Great Britain',
gr=>Greece,
gl=>Greenland,
gd=>Grenada,
gp=>'Guadeloupe (French)',
gu=>'Guam (USA)',
gt=>Guatemala,
gw=>'Guinea Bissau',
gn=>Guinea,
gy=>Guyana,
ht=>Haiti,
hm=>'Heard and McDonald Islands',
va=>'Holy See (Vatican City State)',
hn=>Honduras,
hk=>'Hong Kong',
hu=>Hungary,
is=>Iceland,
in=>India,
id=>Indonesia,
ie=>Ireland,
il=>Israel,
it=>Italy,
ci=>'Ivory Coast (Cote D Ivoire)',
jm=>Jamaica,
jp=>Japan,
jo=>Jordan,
kz=>Kazakhstan,
ke=>Kenya,
ki=>Kiribati,
kw=>Kuwait,
kg=>'Kyrgyz Republic (Kyrgyzstan)',
la=>Laos,
lv=>Latvia,
lb=>Lebanon,
ls=>Lesotho,
lr=>Liberia,
li=>Liechtenstein,
lt=>Lithuania,
lu=>Luxembourg,
mo=>Macau,
mk=>Macedonia,
mg=>Madagascar,
mw=>Malawi,
my=>Malaysia,
mv=>Maldives,
ml=>Mali,
mt=>Malta,
mh=>'Marshall Islands',
mq=>'Martinique (French)',
mr=>Mauritania,
mu=>Mauritius,
yt=>Mayotte,
mx=>Mexico,
fm=>Micronesia,
md=>Moldavia,
mc=>Monaco,
mn=>Mongolia,
ms=>Montserrat,
ma=>Morocco,
mz=>Mozambique,
mm=>Myanmar,
na=>Namibia,
nr=>Nauru,
np=>Nepal,
an=>'Netherlands Antilles',
nl=>Netherlands,
nt=>'Neutral Zone',
nc=>'New Caledonia (French)',
nz=>'New Zealand',
ni=>Nicaragua,
ne=>Niger,
ng=>Nigeria,
nu=>Niue,
nf=>'Norfolk Island',
mp=>'Northern Mariana Islands',
no=>Norway,
om=>Oman,
pk=>Pakistan,
pw=>Palau,
pa=>Panama,
pg=>'Papua New Guinea',
py=>Paraguay,
pe=>Peru,
ph=>Philippines,
pn=>'Pitcairn Island',
pl=>Poland,
pf=>'Polynesia (French)',
pt=>Portugal,
pr=>'Puerto Rico',
qa=>Qatar,
re=>'Reunion (French)',
ro=>Romania,
ru=>'Russian Federation',
rw=>Rwanda,
gs=>'S. Georgia & S. Sandwich Isls.',
sh=>'Saint Helena',
kn=>'Saint Kitts & Nevis Anguilla',
lc=>'Saint Lucia',
pm=>'Saint Pierre and Miquelon',
st=>'Saint Tome (Sao Tome) and Principe',
vc=>'Saint Vincent & Grenadines',
ws=>Samoa,
sm=>'San Marino',
sa=>'Saudi Arabia',
sn=>Senegal,
sc=>Seychelles,
sd=>Scotland,
sl=>'Sierra Leone',
sg=>Singapore,
sk=>'Slovak Republic',
si=>Slovenia,
sb=>'Solomon Islands',
so=>Somalia,
za=>'South Africa',
kr=>'South Korea',
es=>Spain,
lk=>'Sri Lanka',
sr=>Suriname,
sj=>'Svalbard and Jan Mayen Islands',
sz=>Swaziland,
se=>Sweden,
ch=>Switzerland,
tj=>Tadjikistan,
tw=>Taiwan,
tz=>Tanzania,
th=>Thailand,
tg=>Togo,
tk=>Tokelau,
to=>Tonga,
tt=>'Trinidad and Tobago',
tn=>Tunisia,
tr=>Turkey,
tm=>Turkmenistan,
tc=>'Turks and Caicos Islands',
tv=>Tuvalu,
um=>'USA Minor Outlying Islands',
ug=>Uganda,
ua=>Ukraine,
ae=>'United Arab Emirates',
uk=>'United Kingdom',
uy=>Uruguay,
uz=>Uzbekistan,
vu=>Vanuatu,
ve=>Venezuela,
vn=>Vietnam,
vg=>'Virgin Islands (British)',
vi=>'Virgin Islands (USA)',
wf=>'Wallis and Futuna Islands',
eh=>'Western Sahara',
ye=>Yemen,
yu=>Yugoslavia,
zr=>Zaire,
zm=>Zambia,
zw=>Zimbabwe
);
# OPEN TWO CONNECTIONS TO MYSQL DB SERVER
$DB_edirect = DBI->connect('DBI:mysql:kituninc:localhost:', 'web', 'IgfpoatS', {
        RaiseError=>1,
        PrintError=>1
});
$DB2_edirect = DBI->connect('DBI:mysql:kituninc:localhost:', 'web', 'IgfpoatS', {
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
        &request_summary();
        &page_footer();
} elsif ($form{st} == 3) {
        &page_header();
        &request_submit();
        &page_footer();
} elsif ($form{st} == 4) {
        &page_header();
        &order_summary();
        &page_footer();
} elsif ($form{st} == 5) {
        &page_header();
        &order_submit();
        &page_footer();
}

&closeDBConnections();

exit;

###############################################################################
######################## CALCULATE DISCOUNT SUBROUTINE ########################
sub calcDiscount() {
        my ($qty, $case_qty, $list, $case_list) = @_;
        
    my $reg_list = $case_qty * $list;
    my $cases = sprintf("%d", $qty / $case_qty);
    my $case_total = $case_qty * $case_list;
    my $disc_list = $reg_list - $case_total;
    return ($disc_list * $cases);

}
############################# END CALCULATE DISCOUNT ##########################
##############################################################################

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
        $ST_DB = $DB_edirect->prepare("SELECT c.qty, c.mfg_id, c.detail_id, pd.detail_descp, pd.size1, pd.finish, pd.list, pd.case_qty, pd.case_list 
                                            FROM cart c, product_details pd 
                                            WHERE c.session_id = '$session_id'
                                                and c.aff_id = '$aff_id'
                                            and c.detail_id = pd.detail_id
                                                and c.mfg_id = pd.mfg_id");
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
                        ($qty, $mfg_id, $detail_id, $descp, $size, $finish, $list, $case_qty, $case_list) = @$result;

                        if (($case_qty != 0) && ($qty >= $case_qty)) {
                                my $disc_list = &calcDiscount($qty, $case_qty, $list, $case_list);
                                $qty_discount += $disc_list;
                        }
                                        
                        $list *= .75;
                        $list = sprintf("%.2f", $list);
                        my $prod_total = $qty * $list;
                        $prod_total = sprintf("%.2f", $prod_total);
                        $sub_total += $prod_total;
                        print qq^ <TR>
                                <TD class=detail>$qty</TD>
                                <TD class=detail>${mfg_id}${detail_id}</TD><TD class=detail>$size</TD>
                                <TD class=detail>$descp</TD><TD class=detail>$finish</TD>
                                <TD class=detail align=right>\$${list}</TD>
                                <TD class=detail align=right>\$${prod_total}</TD></TR>
                                <TR><TD colspan=7><hr noshade></TD></TR> ^;
                }

                $sub_total = sprintf("%.2f", $sub_total);               
                
                print qq^<TR>
                                <TD colspan=6 align=right class=detail>
                                <b>SUB TOTAL:</b></TD>
                                <TD align=right class=detail>\$${sub_total}</TD></TR>^;
                

        if ($form{st} == 4) {           
        # PRINT CART SUMMARY LINES      
          
          # IF ORDER TOTAL IS LESS THAN $50, SET HANDLING FEE TO $5
                if ($sub_total < 50) {
                        $form{handling} = 5;
                } else {
                        $form{handling} = 0;
                }
                
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
                
          # SALES TAX FOR MINNESOTA CUSTOMERS
                if ($form{cust_bstate} eq 'MN' && ($form{sa} eq 'cart_summary' || $form{sa} eq 'cart_submit')) {
                        $salesTax = &calc_salestax($sub_total);
                        $salesTax = sprintf("%.2f", $salesTax);
                        print qq^ <TR><TD colspan=6 align=right class=detail><b>MN SALES TAX:</b></TD>
                                <TD align=right class=detail>\$${salesTax}</TD></TR> 
                                <input type=hidden name=salestax value=\"$salesTax\">^;
                        $sub_total += $salesTax;
                        
                }

     # PRINT SHIPPING IF SHIPPING METHOD HAS BEEN SELECTED
                if ($display_type eq 'shipping') {
#                       if ($sub_total > 150 && $form{ord_ship_method} eq 'UPS GROUND') {
#                               $ship_cost = 0;
#                               $form{ship_cost} = 0;
#                       }
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
                                <TD align=right class=detail>\$${sub_total}</TD></TR>^; 
        }
        
        print "</table></TD></TR>";
         
        } else {
                &cart_empty();  
        }
} 
############################### END cart_display SUB ##########################                                                                                                                                                                                                                                                                         
###############################################################################

###############################################################################
####################### CLOSE ALL DATABASE CONNECTIONS ########################
sub closeDBConnections() {

$DB_edirect->disconnect();
$DB2_edirect->disconnect();    

}
##################### END CLOSE ALL DATABASE CONNECTIONS SUB ##################
############################################################################### 

###############################################################################
####################### DISPLAY ORDER INPUT FORM SUBROUTINE ###################
sub display_input_form() {
        print qq^<TR><TD><h2 class=top>CHECKOUT->ORDER QUOTE</h2></TD></TR>
                 <TR><form name="orderQuoteForm" method=post action="${secure_cgi}usaorderq.pl" onSubmit="return validateQuoteForm(this)">
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
                        After you have completed all the necessary
                        fields, click the <b>CONTINUE >></b> button.  The next screen will
                        show you a summary of your quote request including all the 
                        information
                        from this screen as well as the items on your order.
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
<OPTION  VALUE="AK">Alaska</option>
<OPTION  VALUE="HI">Hawaii</option>

</select></td>
<td class=reqd>Zip Code:<br>
<input type=text name=cust_bzip  size=10></td>
</tr>
<input type=hidden name=cust_bctry value=us>
<tr>
<td class=reqd>E-mail:<br>
<input type=text name=cust_email size=30 onBlur="validateEmail(this, this.value)"></td>
<td class=reqd colspan=2>Phone:<br>
<input type=text name=cust_bphone  size=30></td>
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
<OPTION  VALUE="AK">Alaska</option>
<OPTION  VALUE="HI">Hawaii</option>
</select></td>
<td class=reqd>Zip Code:<br>
<input type=text name=cust_szip  size=10></td>
</tr>
<input type=hidden name=cust_sctry value=us>
                   </table>
                </td>
                </tr>
                </table>

</TD></TR>
<TR><TD align=center style="padding-top:15px">

<input type=submit name=continue value="CONTINUE >>" class=formButton></TD></TR>
        </form> ^;              
}
###################### END DISPLAY ORDER INPUT FORM SUBROUTINE #################
################################################################################        

################################################################################
######################## SUBMIT QUOTE REQUEST SUBROUTINE #######################
sub order_sumbit() {
        my ($quote_no, $cust_id, $insert_query);
        
        &session_id();
        
        $quote_no = $DB_edirect->selectrow_array("SELECT max(quote_no) + 1 FROM quote_order");

        $cust_id = $DB_edirect->selectrow_array("SELECT max(cust_id) + 1 FROM quote_customers");
        
        if ($form{ship_same} && $form{ship_same} eq 'Y') {
                $form{cust_scompany} = $form{cust_bcompany} if (exists($form{cust_company}));
                $form{cust_sfname} = $form{cust_bfname};
                $form{cust_slname} = $form{cust_blname};
                $form{cust_sadd1} = $form{cust_badd1};
                $form{cust_sadd2} = $form{cust_badd2} if (exists($form{cust_badd2}));
                $form{cust_scity} = $form{cust_bcity};
                $form{cust_sstate} = $form{cust_bstate};
                $form{cust_szip} = $form{cust_bzip};
                $form{cust_sctry} = $form{cust_bctry};
        }
        
        my $q_cust_company = $DB_edirect->quote($form{cust_company});
        my $q_cust_bfname = $DB_edirect->quote($form{cust_bfname});    
        my $q_cust_blname = $DB_edirect->quote($form{cust_blname});    
        my $q_cust_badd1 = $DB_edirect->quote($form{cust_badd1});      
        my $q_cust_badd2 = $DB_edirect->quote($form{cust_badd2}) if (exists($form{cust_badd2}));
        my $q_cust_bcity = $DB_edirect->quote($form{cust_bfname});             
        my $q_cust_scompany = $DB_edirect->quote($form{cust_scompany});
        my $q_cust_sfname = $DB_edirect->quote($form{cust_sfname});    
        my $q_cust_slname = $DB_edirect->quote($form{cust_slname});    
        my $q_cust_sadd1 = $DB_edirect->quote($form{cust_sadd1});      
        my $q_cust_sadd2 = $DB_edirect->quote($form{cust_sadd2}) if (exists($form{cust_sadd2}));
        my $q_cust_scity = $DB_edirect->quote($form{cust_sfname});             
        
        $form{cust_bphone} = &strip_num("$form{cust_bphone}");
        
        $insert_query = "INSERT into quote_customers(cust_id, cust_company,
                        cust_fname, cust_lname, cust_add1, cust_add2, cust_city,
                        cust_state, cust_zip, cust_country, cust_phone, cust_email)
                        VALUES($cust_id, $q_cust_company, $q_cust_bfname, $q_cust_blname,
                        $q_cust_badd1";
                        
        $insert_query .= ", $q_cust_badd2" if (exists($form{cust_badd2}));
        
        $insert_query .= ", $q_cust_bcity, '$form{cust_bstate}', $form{cust_bzip},
                        '$form{cust_bctry}', '$form{cust_bphone}', '$form{cust_email}'";
                         
        $ST_DB = $DB_edirect->do($insert_query);
        
        $insert_query = "INSERT into quote_order(quote_no, cust_id, quote_date,
                ship_company, ship_fname, ship_lname, ship_add1, ship_add2, ship_city,
                ship_state, ship_zip, ship_country, aff_id)
                VALUES($quote_no, $cust_id, NOW(), $q_cust_scompany, $q_cust_sfname, 
                $q_cust_slname, $q_cust_sadd1";
        
        $insert_query .= ", $q_cust_sadd2" if (exists($form{cust_sadd2}));
        
        $insert_query .= ", $q_cust_scity, '$form{cust_sstate}', $form{cust_szip},
                        '$form{cust_sctry}', $aff_id";
                        
        $ST_DB = $DB_edirect->do($insert_query);         
        
        $ST_DB = $DB_edirect->prepare("SELECT line_no, qty, c.mfg_id, c.detail_id, list, 
                        case_qty, case_list, stock 
                        FROM cart c, product_details pd
                        WHERE session_id = '$session_id'
                        and aff_id = $aff_id
                        and c.mfg_id = pd.mfg_id
                        and c.detail_id = pd.detail_id");
        $ST_DB->execute();
        
        while (my @items = $ST_DB->fetchrow_array()) {
                my $discount = 0;
                my ($line, $qty, $mid, $did, $list, $case_qty, $case_list, $stock) = @items;
                if (($case_qty != 0) && ($qty >= $case_qty)) {
                        $discount = &calcDiscount($qty, $case_qty, $list, $case_list);
                        $discount *= .75;
                }
                $list *= .75;
                $list = sprintf("%.2f", $list);
                my $prod_id = $mid . $did;
                $ST2_DB = $DB2_edirect->do("INSERT INTO quote_details(quote_no, line_no, prod_id, 
                                qty_ordered, ext_price, qty_discount, stock)
                                 VALUES($quote_no, $line, '$prod_id', $qty, $list, $discount, '$stock')");
        }
        $ST_DB->finish();

        my ($aff_name, $aff_domain) = $DB_edirect->selectrow_array("SELECT aff_name, aff_domain FROM affiliate WHERE aff_id = $aff_id");
        
        open(MAIL, "$mail") or die "Can't open $mail in sub submit_request";
        print MAIL "To: sales\@$aff_domain\n";
        print MAIL "From: sales\@$aff_domain\n";
        print MAIL "Subject: Quote Request Received\n\n";
        print MAIL "Thank you for requesting a quote from $aff_name. We will review your request, calculate the shipping and send you a complete quote.\n\nCordially,\nCustomer Service\n$aff_name\n\n";
        close MAIL;
        
        open(MAIL, "$mail") or die "Can't open $mail in sub submit_request";
        print MAIL "To: sales\@$aff_domain\n";
        print MAIL "From: sales\@$aff_domain\n";
        print MAIL "Subject: Quote Request Received\n\n";
        print MAIL "A quote has been requested for $aff_name";
        close MAIL;                      
        print "Content-type:text/html\n\n";
        
        
print qq^<tr><td style="padding-top:40px; padding-bottom:40px" align=center>
        Your request has been submitted to our system.  We will respond within 48
        hours.  Thank you.<br><br>
        Customer Service<br>
        <b>$aff_name</b></td></tr>^;

}
########################### END SUB order_submit ##############################
###############################################################################

###############################################################################
######################### QUOTE REQUEST SUMMARY SUB ############################
sub order_summary() {
        my ($aff_name, $aff_domain, $quote_no, $cust_id, $aff_id, $temp, @cust_info, @ship_info); 
        if (!exists($form{i})) {
                print qq^<tr><td style="padding-top:40px;padding-bottom:40px" align=center>Can't perform that action.  Please email the<a href="mailto:webadmin\@usacabinethardware.com">web services department</a>. Thank you.^;
                return;
        } else {
                ($quote_no, $temp) = split(/c/,$form{i});
                ($cust_id, $aff_id) = split(/a/, $temp);
        }
        
        @cust_info = $DB_edirect->selectrow_array("SELECT cust_company, cust_fname, cust_lname, cust_badd1, cust_badd2, cust_city, cust_state, cust_zip, cust_country, cust_email, cust_phone
                FROM quote_customers
                WHERE cust_id = $cust_id
                and aff_id = $aff_id");

        @ship_info = $DB_edirect->selectrow_array("SELECT ship_fname, ship_lname, ship_badd1, ship_badd2, ship_city, ship_state, ship_zip, ship_country, ship_method, ship_cost
                FROM quote_order
                WHERE quote_no = $quote_no
                and cust_id = $cust_id
                and aff_id = $aff_id");

        print qq^<form method=post action=${secure_cgi}usaorderq.pl onSubmit="this.btnOrdSubmit.value='PROCESSING...';this.btnOrdSubmit.disabled=true"> 
                <input type=hidden name=st value=5>     
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
        $form{cust_szip}<br><br>
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
                        <b>If your quote request is correct, press this button to submit
                        it to us. If you 
                        need to change something, use your browser's \"Back\" button to go 
                        back and make your changes.<br><br>
                        
                        </b></font><br>
                                <input name=btnOrdSubmit type=submit value=\"SUBMIT REQUEST\"></form> ^;                                 
                                
        

} 
########################## END SUB order_summary ###@@##########################
################################################################################

###############################################################################
################################ PAGE FOOTER SUBROUTINE #######################
sub page_footer {
        print qq^
        
        <tr>            
        <td><img src="${img_url}space.gif" width=500 height=20></td></tr>
        <tr><td class=footNav>
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
        <tr><td align=center class=tiny>
        Copyright &copy; 2002-2003 usacabinethardware.com<br>
27836 Prairie Rose Rd<br>
Elbow Lake, MN 56531<br>
218.685.6197<br>
<a href="mailto:webadmin\@usacabinethardware.com">webadmin</a>
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
sub page_header {
        print "Content-type: text/html\n\n";
        print qq^<html>
                <head>
         <title></title>^;
  
  if ($ENV{HTTP_HOST} eq 'secure.usacabinethardware.com') {
        print qq^                
         <link rel=\"Stylesheet\" type=\"text/css\" href=\"${secure_url}main.css\">
         <SCRIPT SRC=\"https://secure.usacabinethardware.com/usa.js\"></SCRIPT>\n</head>^;
  } else {
        print qq^                
         <link rel=\"Stylesheet\" type=\"text/css\" href=\"${base_url}main.css\">
         <SCRIPT SRC=\"${base_url}usa.js\"></SCRIPT>\n</head> ^;
  }

  if ($form{a} eq 'b' || $form{a} eq 'di') {
        print "<body margin-width=0 leftmargin=0 margin-height=0 topmargin=0>";
  } else {
        print "<body margin-width=0 leftmargin=0 margin-height=0 topmargin=0>";
  }
  
  print qq^

<table border="0" cellpadding="0" cellspacing="0" width="780">
<tr>
<td>
<!-- START PAGE HEADER IMAGE MAP -->
<map name="m_head">
<area shape="rect" coords="113,56,605,90" href="${base_url}index.html">
<area shape="rect" coords="706,72,773,92" href="${cgi_url}search.html" >
<area shape="rect" coords="696,50,774,71" href="${base_url}contact.html" >
<area shape="rect" coords="695,26,774,47" href="${cgi_url}usastore.pl?a=cart_display" >
<area shape="rect" coords="658,96,774,116" href="${base_url}customer-care.html" >
<area shape="rect" coords="496,97,633,117" href="${base_url}catches-locks.phtml" >
<area shape="rect" coords="360,96,473,116" href="${base_url}drawer-slides.phtml" >
<area shape="rect" coords="276,95,338,115" href="${base_url}hinges.phtml" >
<area shape="rect" coords="130,95,253,116" href="${base_url}knobs-pulls.phtml" >
<area shape="rect" coords="689,6,769,26" href="${cgi_url}usastore.pl?a=cart_checkout" >
<area shape="rect" coords="339,112,340,113" href="#" >
</map><img name="indexhead" src="${img_url}index-head.jpg" width="780"
height="126" border="0"  usemap="#m_head"></td>
<!-- END PAGE HEADER IMAGE MAP -->
</tr>
^;
        
}
############################# END SUB page_header #############################
###############################################################################

###############################################################################
############################### FORM PARSE SUBROUTINE #########################
sub parse {
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

###############################################################################
####################### SUBMIT QUOTE REQUEST SUBROUTINE #######################
sub request_submit() {
        my ($quote_no, $cust_id, $insert_query);
        
        &session_id();
        
        $quote_no = $DB_edirect->selectrow_array("SELECT max(quote_no + 1) FROM quote_order");
        $quote_no = 1000 if (!$quote_no);
        
        $cust_id = $DB_edirect->selectrow_array("SELECT max(cust_id + 1) FROM quote_customers");
        $cust_id = 1000 if (!$cust_id);
        
        if ($form{ship_same} && $form{ship_same} eq 'Y') {
                $form{cust_scompany} = $form{cust_bcompany} if (exists($form{cust_company}));
                $form{cust_sfname} = $form{cust_bfname};
                $form{cust_slname} = $form{cust_blname};
                $form{cust_sadd1} = $form{cust_badd1};
                $form{cust_sadd2} = $form{cust_badd2} if (exists($form{cust_badd2}));
                $form{cust_scity} = $form{cust_bcity};
                $form{cust_sstate} = $form{cust_bstate};
                $form{cust_szip} = $form{cust_bzip};
                $form{cust_sctry} = $form{cust_bctry};
        }
        
        my $q_cust_company = $DB_edirect->quote($form{cust_company});
        my $q_cust_bfname = $DB_edirect->quote($form{cust_bfname});    
        my $q_cust_blname = $DB_edirect->quote($form{cust_blname});    
        my $q_cust_badd1 = $DB_edirect->quote($form{cust_badd1});      
        my $q_cust_badd2 = $DB_edirect->quote($form{cust_badd2}) if (exists($form{cust_badd2}));
        my $q_cust_bcity = $DB_edirect->quote($form{cust_bfname});             
        my $q_cust_scompany = $DB_edirect->quote($form{cust_scompany});
        my $q_cust_sfname = $DB_edirect->quote($form{cust_sfname});    
        my $q_cust_slname = $DB_edirect->quote($form{cust_slname});    
        my $q_cust_sadd1 = $DB_edirect->quote($form{cust_sadd1});      
        my $q_cust_sadd2 = $DB_edirect->quote($form{cust_sadd2}) if (exists($form{cust_sadd2}));
        my $q_cust_scity = $DB_edirect->quote($form{cust_sfname});             
        
        $form{cust_bphone} = &strip_num("$form{cust_bphone}");
        
        $insert_query = "INSERT into quote_customers(cust_id, cust_company,
                        cust_fname, cust_lname, cust_add1, cust_add2, cust_city,
                        cust_state, cust_zip, cust_country, cust_phone, cust_email)
                        VALUES($cust_id, $q_cust_company, $q_cust_bfname, $q_cust_blname,
                        $q_cust_badd1";
                        
        $insert_query .= ", $q_cust_badd2" if (exists($form{cust_badd2}));
        
        $insert_query .= ", $q_cust_bcity, '$form{cust_bstate}', '$form{cust_bzip}',
                        '$form{cust_bctry}', '$form{cust_bphone}', '$form{cust_email}')";
                         
        $ST_DB = $DB_edirect->do($insert_query);
        
        $insert_query = "INSERT into quote_order(quote_no, cust_id, quote_date,
                ship_company, ship_fname, ship_lname, ship_add1, ship_add2, ship_city,
                ship_state, ship_zip, ship_country, aff_id, status, status_date)
                VALUES($quote_no, $cust_id, NOW(), $q_cust_scompany, $q_cust_sfname, 
                $q_cust_slname, $q_cust_sadd1";
        
        $insert_query .= ", $q_cust_sadd2" if (exists($form{cust_sadd2}));
        
        $insert_query .= ", $q_cust_scity, '$form{cust_sstate}', '$form{cust_szip}',
                        '$form{cust_sctry}', $aff_id, 'NEW', NOW())";
                        
        $ST_DB = $DB_edirect->do($insert_query);         
        
        $ST_DB = $DB_edirect->prepare("SELECT line_no, qty, c.mfg_id, c.detail_id, list, 
                        case_qty, case_list, stock 
                        FROM cart c, product_details pd
                        WHERE session_id = '$session_id'
                        and aff_id = $aff_id
                        and c.mfg_id = pd.mfg_id
                        and c.detail_id = pd.detail_id");
        $ST_DB->execute();
        
        while (my @items = $ST_DB->fetchrow_array()) {
                my $discount = 0;
                my ($line, $qty, $mid, $did, $list, $case_qty, $case_list, $stock) = @items;
                if (($case_qty != 0) && ($qty >= $case_qty)) {
                        $discount = &calcDiscount($qty, $case_qty, $list, $case_list);
                        $discount *= .75;
                }
                $list *= .75;
                $list = sprintf("%.2f", $list);
                my $prod_id = $mid . $did;
                $ST2_DB = $DB2_edirect->do("INSERT INTO quote_details(quote_no, line_no, 
                                prod_id, qty_ordered, ext_price, qty_discount, stock)
                                 VALUES($quote_no, $line, '$prod_id', $qty, $list, $discount, 
                                '$stock')");
        }
        $ST_DB->finish();

        my ($aff_name, $aff_domain) = $DB_edirect->selectrow_array("SELECT aff_name, aff_domain FROM affiliate WHERE aff_id = $aff_id");
        
        open(MAIL, "$mail") or die "Can't open $mail in sub submit_request";
        print MAIL "To: sales\@$aff_domain\n";
        print MAIL "From: sales\@$aff_domain\n";
        print MAIL "Subject: Quote Request Received\n\n";
        print MAIL "Thank you for requesting a quote from $aff_name. We will review your request, calculate the shipping and send you a complete quote.\n\nCordially,\nCustomer Service\n$aff_name\n\n";
        close MAIL;
        
        open(MAIL, "$mail") or die "Can't open $mail in sub submit_request";
        print MAIL "To: sales\@$aff_domain\n";
        print MAIL "From: sales\@$aff_domain\n";
        print MAIL "Subject: Quote Request Received\n\n";
        print MAIL "A quote has been requested for $aff_name";
        close MAIL;                      
        print "Content-type:text/html\n\n";
        
        
print qq^<tr><td style="padding-top:40px; padding-bottom:40px" align=center>
        Your request has been submitted to our system.  We will respond within 48
        hours.  Thank you.<br><br>
        Customer Service<br>
        <b>$aff_name</b></td></tr>^;

}
########################### END SUB request_submit ############################
###############################################################################

###############################################################################
######################### QUOTE REQUEST SUMMARY SUB ############################
sub request_summary {
        
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

        print qq^<form method=post action=${secure_cgi}usaorderq.pl onSubmit="this.btnOrdSubmit.value='PROCESSING...';this.btnOrdSubmit.disabled=true"> 
                <input type=hidden name=st value=3>     
                <input type=hidden name=sid value=$session_id>  
                ^;
        
  #PRINT CUSTOMER INFO
        print qq^ <TR><TD><H2 class=top>CHECKOUT->QUOTE SUMMARY</H2></TD></TR>
                        
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
        $form{cust_szip}<br><br>
        </td></tr><tr><td valign=top colspan=2>^;
                        
        &cart_display();

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
                        <b>If your quote request is correct, press this button to submit
                        it to us. If you 
                        need to change something, use your browser's \"Back\" button to go 
                        back and make your changes.<br><br>
                        
                        </b></font><br>
                                <input class=formButton name=btnOrdSubmit type=submit value=\"SUBMIT REQUEST\"></form> ^;                                
                                
        

} 
########################## END SUB request_summary #############################
################################################################################

################################################################################
######################## SESSION-ID SUBROUTINE #################################
sub session_id {

        # FIRST CHECK TO SEE IF USER HAS A CURRENT SESSION 
        # BY CHECKING FOR A SESSION_ID CODED INTO HTML PAGE
        # OR IF USER HAS A COOKIE. IF NONE OF THESE EXIST
        # LOOKUP LAST SESSION IN SESSIONS TABLE AND INCREMENT
        # BY 1 AND CREATE NEW SESSION

        if ($session_id eq '') {
      ##LOCK sessions TABLE FOR THIS SESSION
        $ST_DB = $DB_edirect->do("LOCK TABLES sessions WRITE, orders WRITE");
        
        if ($form{sid} && $form{sid} ne 'get') {
                        $session_id = $form{sid};
        } elsif ($ENV{HTTP_COOKIE}) {
                my ($gar, $tmp_sid) = split(/=/, $ENV{HTTP_COOKIE});
                $session_id = $tmp_sid;
        }else {
                $ST_DB = $DB_edirect->prepare("SELECT session_id
                                                                FROM sessions
                                                                WHERE ip_address = '$ENV{REMOTE_ADDR}'");
                $ST_DB->execute();
                $session_id = $ST_DB->fetchrow_array();
                $ST_DB->finish();
        }
        
        if ($session_id eq '') {
                do {
                        $ST_DB = $DB_edirect->prepare("SELECT NOW() + 0");       
                        $ST_DB->execute();
                        $session_id = $ST_DB->fetchrow_array();
                        $ST_DB->finish();
                        
                }       
                while ($DB_edirect->selectrow_array("SELECT inv_no FROM orders WHERE
                                                                session_id = '$session_id'"));
                                                                
                $ST_DB = $DB_edirect->do("INSERT INTO sessions 
                                                VALUES ($session_id, '$ENV{REMOTE_ADDR}')");
        }
        
      ##UNLOCK sessions TABLE FOR THIS SESSION
        $ST_DB = $DB_edirect->do("UNLOCK TABLES");
        }
} 
############################### END SUB session_id ############################
###############################################################################

###############################################################################
# SUB strip_num TO STRIP UNNECESSARY CHARACTERS AND SPACES FROM A NUMBER STRING
sub strip_num() {
        
        $_[0] =~ s/\s//g;
        $_[0] =~ s/\D//g;
                
        return $_[0];   

}
############################## END SUB strip_num ##############################
###############################################################################

