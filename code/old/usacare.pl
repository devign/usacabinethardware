#!/usr/bin/perl 

# DATE: 08/13/06
# AUTH: J.W. Raugutt
# PROG: usacare.pl
# DESC: usacabinethardware.com customer care application
# Uses edirect shared MYSQL database.

# REVISIONS:

# call in DBI 
use DBI;
require qw(usalib.pl);

# call HTML form parsing subroutine
&parse();

# DECLARE GLOBAL VARIABLES
$action = $form{a};
$img_url = 'https://secure.usacabinethardware.com/img/';
$cgi_url = 'http://www.usacabinethardware.com/cgi-bin/';
$secure_cgi = 'https://secure.usacabinethardware.com/cgi-bin/';
$base_url = 'http://www.usacabinethardware.com/';
$secure_url = 'https://secure.usacabinethardware.com/';
$home_dir = '/vhosts/usacabinethardware.com/htdocs/';
#$home_dir = '/var/www/html/usa/';
$mail = '/usr/sbin/sendmail -t';
$site_id = '4';
$return_mail = 'orders@usacabinethardware.com';

# OPEN TWO CONNECTIONS TO MYSQL DB SERVER
$DB_edirect = DBI->connect('DBI:mysql:edirect:localhost:', 'edweb', 'gh0rAc', {
        RaiseError=>1,
        PrintError=>1
});
$DB2_edirect = DBI->connect('DBI:mysql:edirect:localhost:', 'edweb', 'gh0rAc', {
        RaiseError=>1,
        PrintError=>1
});


if ($action eq 'os') {
        &page_header();
        &order_status();
        &page_footer();
} elsif ($action eq 'rga') {
        &page_header();
        &return_request();
        &page_footer();
} else {
        &page_header();
        print qq^<tr><td align=center style="padding:100px"><b>NOTHING TO DO!</b>
                                </td></tr>^;
        &page_footer();
}

&closeDBConnections();

exit;

###############################################################################
########################## CUSTOMER LOGIN SUBROUTINE ##########################
sub cust_login() {
    $ST_DB = $DB_edirect->prepare("SELECT cust_id, cust_company, cust_fname, 
                        cust_lname,     cust_add1, cust_add2, cust_city, cust_state, 
                        cust_zip, cust_country, cust_email, cust_numorders
                        FROM customers
                        where STRCMP(cust_userid, '$form{retcust_uid}') = 0
                        and STRCMP(cust_pwd, '$form{retcust_pwd}') = 0");
    $ST_DB->execute() or die "Can't perform select customer info in sub summary: $DBI::errstr";
    
    @results = $ST_DB->fetchrow_array();
    $ST_DB->finish();
    
    if ($results[0] eq '') {
        &user_pass_error('invalid');
        &page_footer();
        &closeDBConnections();
        exit;
    }
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
    $form{cust_numorders} = $results[11];
                
        print qq^<tr>
<td valign="top" align="center"><h2 class="top"><a href="$base_url}customer-care.html" style="text-decoration:none">CUSTOMER CARE</a>->CUSTOMER LOGIN</h2>
        <table border="1" bordercolor="#000000" cellpadding="5" cellspacing="0" width="740">    
        <tr><td>Welcome $form{cust_fname}!</td></tr>
        <tr><td class=detail align=center>Your Information</td></tr>
        <tr><td align=center>
                <table border=1 cellpadding=5 cellspacing=0 with=440>   
                <tr><td class=detailB colspan=2>COMPANY:<br>
                <input type=text name=cust_company value="$form{cust_company}" size=30>
                </td></tr>
                <tr><td class=detailB>FIRST NAME:<br>
                <input type=text name=cust_fname value="$form{cust_fname}" size=30>
                </td>
                <td class=detailB>LAST NAME:<br>
                <input type=text name=cust_lname value="$form{cust_lname}" size=30>
                </td></tr>
                <tr><td class=detailB>ADDRESS 1:<br>
                <input type=text name=cust_badd1 value="$form{cust_badd1}" size=30>
                </td>
                <td class=detailB>ADDRESS 2:<br>
                <input type=text name=cust_badd2 value="$form{cust_badd2}" size=30>
                </td></tr>^;
}
######################## END CUSTOMER LOGIN SUBROUTINE ########################
############################################################################### 

###############################################################################
######################### BEGIN mail_store SUBROUTINE #########################
sub mail_store() {
        my ($msg, $title, $source) = @_;
        my $entire_message;
        
        open(MAIL, "|$mail") or die "Can't open sendmail in mail_store sub!";
        
        print MAIL "To: $return_mail\n";
        print MAIL "From: $return_mail\n";
        print MAIL "Subject: $title\n\n";
        
        $entire_message = "$msg";
        
        if ($source) {
                $entire_message .= "\nAction was performed by $source.";
        }
        
        print MAIL "$entire_message";
        
        close MAIL;
        
}
###################### MAIL MESSAGE TO mail_store SUBROUTINE ##################
###############################################################################

###############################################################################
############################# order_status SUBROUTINE #########################
sub order_status() {
        my ($status, $status_date);
        
        ($status, $status_date) = $DB_edirect->selectrow_array("SELECT status, status_date
                        FROM orders WHERE inv_no = $form{inv_no} and site_id = $site_id");
                        
        if (!$status) {
                print qq^<tr><td style="padding-top:40px; padding-left:100px; padding-bottom:40px;padding-right:100px;">
                                The order number you entered is not a valid order number
                                from USACabinetHardware.com.  To inquire about your order
                                and/or this message, please 
                                <a href="mailto:service\@usacabinethardware.com?Subject=Order_Status">email</a> us.
                                <br><br><br><br>

                                </td></tr>^;
        } else {
                print qq^<tr><td style="padding-top:40px; padding-left:100px; padding-bottom:40px">
                                The status of order number <b>$form{inv_no}</b> is:<br><br>
                                <b>$status</b> as of <b>$status_date</b>
                                <br><br>To inquire about your order
                                and/or this message, please 
                                <a href="mailto:service\@usacabinethardware.com?Subject=Order#$form{inv_no}">email</a> us.
                                </td></tr>^;            
        }
                                 
}
########################### END order_status SUBROUTINE #######################
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

###############################################################################
######################### return_request SUBROUTINE ###########################
sub return_request() {
        my (@order_info, @cust_info, @items);
        if ($form{step} == 1) {
                my $q_company = $DB_edirect->quote("$form{rr_company}") if ($form{rr_company});
                my $q_name = $DB_edirect->quote("$form{rr_name}") if ($form{rr_name});
                my $query = "SELECT o.cust_id, ship_company, ship_fname, 
                                                         ship_lname, ship_add1, ship_add2, ship_city, 
                                                         ship_state, ship_zip
                                                         FROM orders o, customers c
                                                         WHERE inv_no = '$form{inv_no}'
                                                         and o.cust_id = c.cust_id";
                if ($form{rr_company}) {
                        $query .= " and cust_company = $q_company";
                } else {
                        $query .= " and cust_lname = $q_name";
                }
                
                $ST_DB = $DB_edirect->prepare("$query");
                $ST_DB->execute();
                @order_info = $ST_DB->fetchrow_array();
                
                if (!@order_info) {
                        print qq^<tr><td style="padding-top:40px" align=center><br><br>
                                <table border=0 cellpadding=5 width=400>
                                <tr><td><font size=2>
                                I AM UNABLE TO PROCESS YOUR REQUEST...<br><br>
                                <b>-></b>MAKE SURE YOU ARE USING THE 4 OR 5 DIGIT ORDER # YOU RECEIVED
                                FROM US WHEN YOU PLACED YOUR ORDER<br><br>
                                <b>-> </b>MAKE SURE YOU ARE TYPING THE <b>BILLING LAST NAME</b> 
                                                <i>EXACTLY</i> AS
                                                IT APPEARED ON THE ORDER # YOU ARE TRYING TO LOCATE
                                <br><br>
                                <center>CLICK TO GO
                                <a href="javascript:history.back()">BACK</a></center>
                                <br><br>IF YOU CONTINUE TO HAVE TROUBLES, GIVE US A CALL, 
                                WE'LL BE HAPPY TO HELP YOU OVER THE PHONE 1.877.281.7905
                                <br><br></td></tr></table></td></tr>^;
                        return;
                }
                
                @cust_info = $DB_edirect->selectrow_array("SELECT cust_company, cust_fname, 
                                                         cust_lname, cust_add1, cust_add2, cust_city, 
                                                         cust_state, cust_zip
                                                         FROM customers
                                                         WHERE cust_id = '$order_info[0]'");
                
                print qq^<tr>
<td valign="top" align="center"><h2 class="top"><a href="customer-care.html" style="text-decoration:none">CUSTOMER CARE</a>->RGA REQUEST</h2>
        <table border="1" bordercolor="#000000" cellpadding="5" cellspacing="0" width="640">
        <tr>
        <td class="detail" valign="top" colspan="2">
                                 <form name=requestForm method=post action="usacare.pl">
                                 <input type=hidden name=a value=rga>
                                 <input type=hidden name=step value=2>
                                 <input type=hidden name=inv_no value="$form{inv_no}">
                                 <input type=hidden name=rr_company value="$form{rr_company}">
                                 <input type=hidden name=rr_name value="$form{rr_name}">
                                 <input type=hidden name=rr_email value="$form{rr_email}">
                                 <input type=hidden name=rr_reason value="$form{rr_reason}">
                        <input type=hidden name=rr_new_email value="$form{rr_new_email}">
    <table border=0 width=100% cellpadding=5 cellspacing=0>
                                        <tr><td colspan=2><b>ORDER #: $form{inv_no}</b></td></tr>
                                        <tr><td valign=top><b>BILLING INFO:</b><br>^;
                
                print "$cust_info[0]<br>" if ($cust_info[0]);
                print qq^$cust_info[1] $cust_info[2]<br>
                                 $cust_info[3]<br>^;
                print "$cust_info[4]<br>" if ($cust_info[4]);
                print qq^$cust_info[5], $cust_info[6] $cust_info[7]</td>
                                <td valign=top><b>SHIPPING INFO:</b><br>^;
                print "$order_info[1]<br>" if ($order_info[1]);
                print qq^$order_info[2] $order_info[3]<br>
                                 $order_info[4]<br>^;
                print "$order_info[5]<br>" if ($order_info[5]);
                print qq^$order_info[6], $order_info[7] $order_info[8]</td></tr>
                                <tr><td colspan=2><font size=2>The following items are what you 
                                originally                      
                                ordered. Please enter the quantity of each item you want to 
                                return in the QTY RETURNING text field.</td></tr>^;
                                
                $ST_DB = $DB_edirect->prepare("SELECT qty_ordered, prod_id, ext_price
                                                          FROM order_details
                                                          WHERE inv_no = '$form{inv_no}'
                                                          ORDER BY line_no");
                $ST_DB->execute();
                
                print qq^<tr><td colspan=2>
                                        <table border=0 cellpadding=3 cellspacing=0 width=100%>
                                        <tr><th>QTY RETURNING</th><th>QTY ORDERED</th>
                                        <th>PRODUCT ID</th><th>PRICE</th></tr>^;
                                        
                while (@items = $ST_DB->fetchrow_array()) {
                        print qq^<tr><td><input type=text name=$items[1]_qty size=4></td>
                                <input type=hidden name="$items[1]_price" value="$items[2]">^;
                        print qq^<td>$items[0]</td><td>$items[1]</td><td>$items[2]</td>
                                        </tr>^;
                }
                $ST_DB->finish();
                
                print qq^</table></td></tr>
                                <tr><td colspan=2 align=center>
                                <button onClick="javascript:history.back()">
                                BACK TO CHANGE ORDER #</button>
                                <input type=submit value="SUBMIT REQUEST">
                                </form>
                                </td></tr></table>^;
                
        
        } else {
                my $qty_check = 0;
                foreach $key (sort keys %form) {
                        if ($key =~ m/_qty$/) {
                                if ($form{$key} ne '') {
                                        $qty_check = 1;
                                        last;
                                }
                        }
                }
                
                if ($qty_check == 0) {
                        print qq^<tr><td style="padding-top:40px" align=center><br><br>
                                <table border=0 cellpadding=5 width=400>
                                <tr><td><font size=2>
                                I AM UNABLE TO PROCESS YOUR REQUEST...<br><br>
                                <b>-></b>PLEASE ENTER THE QUANTITY OF EACH ITEM YOU WISH TO
                                RETURN IN THE INPUT BOX UNDER <b>QTY RETURNING</b>
                                <br><br>
                                <center>CLICK TO GO
                                <a href="javascript:history.back()">BACK</a></center>
                                <br><br></td></tr></table></td></tr>^;
                        return;
                }               
                        
                my $po_no = $DB_edirect->selectrow_array("SELECT po_num FROM orders
                        WHERE inv_no = '$form{inv_no}'");
                                
                my $q_rr_reason = $DB_edirect->quote($form{rr_reason});
                my $q_rr_email = $DB_edirect->quote($form{rr_email});
                $ST_DB = $DB_edirect->do("INSERT into return_request(rr_invno, rr_date, 
                                                rr_email, rr_reason, rr_status, rr_statusdate)
                                                VALUES('$form{inv_no}', NOW(), $q_rr_email, 
                                                $q_rr_reason, 'NEW', NOW())");
                                                
                my $line_no = 1;                                
                foreach $key (sort keys %form) {
                        if ($key =~ m/_qty$/ && $form{"$key"} ne '' && $form{"$key"} != 0) {
                                my ($prod_id, $gar) = split(/_/, $key);
                                my $qty = $form{"$key"};
                                my $extPrice = $form{"${prod_id}_price"};
                                my $vid = $DB2_edirect->selectrow_array("SELECT vend_id FROM po_details
                                        WHERE po_num = '$po_no'
                                        and prod_id = '$prod_id'");                     
                                my $discount = $DB_edirect->selectrow_array("SELECT 
                                                IFNULL(disc_amt, 0) 
                                                FROM order_details
                                                WHERE inv_no = '$form{inv_no}'
                                                and prod_id = '$prod_id'");                     
                                $ST_DB = $DB_edirect->do("INSERT into rr_details(rr_invno, rr_line_no,
                                                                rr_prod_id, rr_qty, rr_ext_price, rr_discount, 
                                                                rr_vend_id)     
                                                                VALUES('$form{inv_no}', $line_no, '$prod_id',
                                                                $qty, $extPrice, $discount, '$vid')");
                        $line_no++;
                        }
                }
                

                print qq^<tr><td style="padding-top:40px; padding-bottom:40px" align=center><br><br>
                                Your request has been submitted for
                                processing, you will also receive an email confirmation shortly.
                                <br>Thank you<br><i>Customer Care</i></td></tr>^;

                
                open(MAIL, "|$mail") or die "Open $mail in sub return_request failed";
                open(MAIL2, "|$mail") or die "Open $mail in sub return_request failed";
                
                print MAIL "To: $form{rr_email}\n";
                print MAIL "From: rma\@usacabinethardware.com\n";
                print MAIL "Subject: RMA REQUEST CONFIRMATION\n\n";
                
                print MAIL "Your request for a return authorization number has been received.  You will receive another email, usually within 3 business days, with your RMA # and instructions for returning the product(s).  If you have any questions, please email us at rma\@usacabinethardware.com or call us at 1.877.281.7905.\n\nCordially,\nCustomer Care\nUSACabinetHardware.com";
                
                close(MAIL);
                
                print MAIL2 "To: rma\@usacabinethardware.com\n";
                print MAIL2 "From: $form{rr_email}\n";
                print MAIL2 "Subject: NEW RMA REQUEST\n\n";
                
                print MAIL2 "An RMA has been requested for usacabinethardware.com";
                
                close(MAIL2);   
                
        }       
                                                                                        
}                               
############################# END return_request SUB ##########################
###############################################################################

###############################################################################
###################### USER/PASS ERROR MESSAGE SUBROUTINE #####################
sub user_pass_error() {
        my $this_error = shift @_;
        
        if ($this_error eq 'invalid') {
                print qq^<tr><td align=center style="padding-top:40px;padding-bottom:40px">
                                <table border=0 width=400>
                                <tr><td align=center><font size=4 color=\"#C50015\">
                                THE USERNAME AND PASSWORD YOU ENTERED
                                DOES NOT MATCH ANY USERNAME PASSWORD COMBINATIONS IN OUR SYSTEM.  
                                PLEASE
                                <a href="${base_url}customer-care.html">CLICK HERE</a> TO 
                                RE-ENTER.
                                </td></tr></table></td></tr>^;
        } else {
                print qq^<tr><td align=center style="padding-top:40px;padding-bottom:40px">
                                <table border=0 width=400>
                                <tr><td align=center><font size=4 color=\"#C50015\">
                                THE USERNAME YOU HAVE CHOSEN IS ALREADY
                                IN USE BY ANOTHER USER ON THE SYSTEM.  PLEASE
                                <a href="javascript:history.back()">CLICK HERE</a> TO CHOSE ANOTHER ONE.
                                </td></tr></table></td></tr>^;
        }
}
########################## END SUB user_pass_error ############################
###############################################################################
