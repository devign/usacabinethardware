//CLOSE THE CURRENT WINDOW
function closeWin() {
        this.window.close();
} 

//SELECT LIST NAVIGATION
function linkMenu(form) {
        var myindex=form.dest.selectedIndex
        window.open(form.dest.options[myindex].value, target="_parent", "toolbar=yes,scrollbars=yes,location=yes"); 
}

                
function productView(img, product) {
        prodImage = new Image();
        prodImage.src=img;
        if (prodImage.width < 700) {
                prodImageWidth = prodImage.width + 80;
        } else {
                prodImageWidth = 760;
        }
        if (prodImage.height < 500) {
                prodImageHeight = prodImage.height + 100;
        } else {
                prodImageHeight = 580;
        }
        thisWindow=window.open("", "productWindow", "width=" + prodImageWidth + ", height=" + prodImageHeight + ", resizable, scrollbars=1");
        thisWindow.document.write("<HTML><HEAD><TITLE>PRODUCT VIEWER: " + product + "</TITLE><link rel=stylesheet href=http://www.usacabinethardware.com/productView.css></HEAD>");
                        
        thisWindow.document.write("<BODY BGCOLOR=FFFFFF><H3>" + product + "</H3>");
                        
        thisWindow.document.write("<img src=" + prodImage.src + "><BR><A HREF=JAVASCRIPT:window.close()>CLOSE</a></BODY></HTML>");
                        
} 

function returnRequest(f, s) {
        if (s == 1) {
                if (f.rr_company.value == "" && f.rr_name.value == "") {
                        alert("Please enter a company name or your first and last name!");
                        f.rr_name.focus();
                        return false;
                }
                
                if (f.rr_email.value == "") {
                        alert("Please enter your email address!");
                        f.rr_email.focus();
                        return false;
                } 
                
                if (f.inv_no.value == "") {
                        alert("Please enter your USA Cabinet Hardware order number!");
                        f.inv_no.focus();
                        return false;
                } 
                
                if (f.rr_reason.value == "") {
                        alert("Please enter your reason for return!");
                        f.rr_reason.focus();
                        return false;
                }       
                        
                f.method = "post";
                f.action = "https://www.usacabinethardware.com/cgi-bin/usacare.pl";
                f.submit();
                return true;
        
        } 
        
/*      else {
                if (confirm("Is everything correct on your return request?")) {
                        f.method = "post";
                        f.action = "https://www.usacabinethardware.com/cgi-bin/usacare.pl";
                        f.submit();     
                } else {
                        return false;
                }
        }
*/      
}
                        
                                
function secureAlert() {
        alert("You are entering secure mode...");
        return true;
}

function showProdId(div, pid) {
	document.getElementById(div).innerHTML = pid;
}
	
function validateAgreement(frm) {
        var valid = true;
               
        if (frm.policy_agree.checked == false) {
                valid = false;
        } 

        if (valid == false) {
                alert("You cannot proceed with your order\nunless you agree with our policies");
                frm.policy_agree.focus();

        }
        if (valid == true) {
                frm.ordSubmitBut.value='PROCESSING...';        
                frm.ordSubmitBut.disabled='true'
                frm.method="post";
                frm.action='https://secure.usacabinethardware.com/cgi-bin/usastore.pl';
                frm.submit();
         
        }                        
        return valid;
}  

function validateBilling(frm, loc) {
        var valid = true;
        if (frm.cust_bfname.value == "") {
                alert("Please enter the first name!");
                frm.cust_bfname.focus();
                valid = false;
                return valid;
        }               
        if (frm.cust_blname.value == "") {
                alert("Please enter the last name!");
                frm.cust_blname.focus();
                valid = false;
                return valid;
        }                       
        if (frm.cust_badd1.value == "") {
                alert("Please enter the address!");
                frm.cust_badd1.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_bcity.value == "") {
                alert("Please enter the city!");
                frm.cust_bcity.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_bstate.value == "XX") {
                alert("Please select a state!");
                frm.cust_bstate.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_bzip.value == "") {
                alert("Please enter a zip code!");
                frm.cust_bzip.focus();
                valid = false;
                return valid;
        }               
        if (frm.cust_bphone.value == "") {
                alert("Please enter your phone number!");
                frm.cust_bphone.focus();
                valid = false;
                return valid;
        }               
        if (frm.cust_email.value == "") {
                alert("Please enter your email address!");
                frm.cust_email.focus();
                valid = false;
                return valid;
        }
        if (frm == "billForm2") {       
                if (frm.cust_uid.value != "") {
                        if (frm.cust_pwd.value == "") {
                                alert("Please enter a password!");
                                frm.cust_pwd.focus();
                                valid = false;
                                return valid;
                        }
                        if (frm.cust_pwd2.value == "") {
                                alert("Please re-enter your password for validation!");
                                frm.cust_pwd2.focus();
                                valid = false;
                                return valid;
                        }
                }
        }       
        
        return valid;
                                                                                                                        
}

function validateEmail(efield, email) {
        regExp = /^[a-zA-Z0-9._-]+@([a-zA-Z0-9.-]+\.)+[a-zA-Z0-9.-]{2,4}$/;

        if (!regExp.test(email)) {
                alert("Please enter a valid email address!");
                efield.focus();
                return false;
        }
        return true;
}

function validateOrderForm(frm) {
        var valid = true;
		frm.orderSubmitButton.disabled = 1;
		
        if (frm.cust_bfname.value == "") {
                alert("Please enter the first name!");
                frm.cust_bfname.focus();
                valid = false;
				frm.orderSubmitButton.disabled = 0;
                return valid;
        }               
        if (frm.cust_blname.value == "") {
                alert("Please enter the last name!");
                frm.cust_blname.focus();
                valid = false;
				frm.orderSubmitButton.disabled = 0;
                return valid;
        }                       
        if (frm.cust_badd1.value == "") {
                alert("Please enter the address!");
                frm.cust_badd1.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_bcity.value == "") {
                alert("Please enter the city!");
                frm.cust_bcity.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_bstate.value == "XX") {
                alert("Please select a state!");
                frm.cust_bstate.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_bzip.value == "") {
                alert("Please enter a zip code!");
                frm.cust_bzip.focus();
                valid = false;
                return valid;
        }               
        if (frm.cust_bphone.value == "") {
                alert("Please enter your phone number!");
                frm.cust_bphone.focus();
                valid = false;
                return valid;
        }               
        if (frm.cust_email.value == "") {
                alert("Please enter your email address!");
                frm.cust_email.focus();
                valid = false;
                return valid;
        }

        regExp = /^[a-zA-Z0-9._-]+@([a-zA-Z0-9.-]+\.)+[a-zA-Z0-9.-]{2,4}$/;

        if (!regExp.test(frm.cust_email.value)) {
                alert("Please enter a valid email address!");
                frm.cust_email.focus();
                valid = false;
                return valid;
        }
		    
        if (frm.cust_uid.value != "") {
               if (frm.cust_pwd.value == "") {
                                alert("Please enter a password!");
                                frm.cust_pwd.focus();
                                valid = false;
                                return valid;
               }
               if (frm.cust_pwd2.value == "") {
                                alert("Please re-enter your password for validation!");
                                frm.cust_pwd2.focus();
                                valid = false;
                                return valid;
               }
			   
			   if (frm.cust_pwd.value != frm.cust_pwd2.value) {
               		alert("Please retype your passwords, they do not match!");
               		frm.cust_pwd.focus();
               		frm.cust_pwd.select();
               		valid = false; 
					return valid;
        		}
        }
               

		if (frm.cust_sfname.value == "") {
                alert("Please enter the first name!");
                frm.cust_sfname.focus();
                valid = false;
                return valid;
        }               
        if (frm.cust_slname.value == "") {
                alert("Please enter the last name!");
                frm.cust_slname.focus();
                valid = false;
                return valid;
        }                       
        if (frm.cust_sadd1.value == "") {
                alert("Please enter the address!");
                frm.cust_sadd1.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_scity.value == "") {
                alert("Please enter the city!");
                frm.cust_scity.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_sstate.value == "XX") {
                alert("Please select a state!");
                frm.cust_sstate.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_szip.value == "") {
                alert("Please enter a zip code!");
                frm.cust_szip.focus();
                valid = false;
                return valid;
        }               

    	if (frm.cust_ccnum.value == "") {
                    alert("Please enter your " + frm.ord_pay_method.value + " card number!");
                    frm.cust_ccnum.focus();
                    valid = false;
                	return valid;
            }
        if (frm.ord_pay_method.value == "AMEX") {
            if (frm.cust_cccode.value == "" || 
                            frm.cust_cccode.value.length < 4) {
                    alert("Please enter the 4 digit CCV code located\n on the front of your American Express card!");
                    frm.cust_cccode.focus();
                    valid = false;
                	return valid;
            }
        } else {
            if (frm.cust_cccode.value == "" || 
                            frm.cust_cccode.value.length < 3) {
                    alert("Please enter the 3 digit CCV code\n located on the back of your credit card!");
                    frm.cust_cccode.focus();
                    valid = false;
                	return valid;
            }
        }
            
        if (frm.cust_ccmo.selectedIndex == 0) {
            alert("Please enter a valid\n card expiration month!");
            frm.cust_ccmo.focus();
            valid = false;
            return valid;
        }
        
        if (frm.cust_ccyear.selectedIndex == 0) {
            alert("Please enter a valid\n card expiration year!");
            frm.cust_ccyear.focus();
            valid = false;
            return valid;
        }   

        return valid;

}

function validatePayment(frm) {
		var valid = true;
		
    	if (frm.cust_ccnum.value == "") {
                    alert("Please enter your " + frm.ord_pay_method.value + " card number!");
                    frm.cust_ccnum.focus();
                    valid = false;
                	return valid;
            }
        if (frm.ord_pay_method.value == "AMEX") {
            if (frm.cust_cccode.value == "" || 
                            frm.cust_cccode.value.length < 4) {
                    alert("Please enter the 4 digit CCV code located\n on the front of your American Express card!");
                    frm.cust_cccode.focus();
                    valid = false;
                	return valid;
            }
        } else {
            if (frm.cust_cccode.value == "" || 
                            frm.cust_cccode.value.length < 3) {
                    alert("Please enter the 3 digit CCV code\n located on the back of your credit card!");
                    frm.cust_cccode.focus();
                    valid = false;
                	return valid;
            }
        }
            
        if (frm.cust_ccmo.selectedIndex == 0) {
            alert("Please enter a valid\n card expiration month!");
            frm.cust_ccmo.focus();
            valid = false;
            return valid;
        }
        
        if (frm.cust_ccyear.selectedIndex == 0) {
            alert("Please enter a valid\n card expiration year!");
            frm.cust_ccyear.focus();
            valid = false;
            return valid;
        }   

		return valid;
	
}


function validatePwd(frm) {
        var valid;
                
        if (frm.cust_pwd.value == frm.cust_pwd2.value) {
                valid = true;
        } else {
                alert("Please retype your passwords, they do not match!");
                frm.cust_pwd.focus();
                frm.cust_pwd.select();
                valid = false;
        }
                        
        return valid;
}       

function validateQuoteForm(frm) {
        var valid = true;
        if (frm.cust_bfname.value == "") {
                alert("Please enter the first name!");
                frm.cust_bfname.focus();
                valid = false;
                return valid;
        }               
        if (frm.cust_blname.value == "") {
                alert("Please enter the last name!");
                frm.cust_blname.focus();
                valid = false;
                return valid;
        }                       
        if (frm.cust_badd1.value == "") {
                alert("Please enter the address!");
                frm.cust_badd1.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_bcity.value == "") {
                alert("Please enter the city!");
                frm.cust_bcity.focus();
                valid = false;
                return valid;
        }       
        
        if (frm.cust_bctry.value == 'us') {
                if (frm.cust_bstate.value == "XX") {
                        alert("Please select a state!");
                        frm.cust_bstate.focus();
                        valid = false;
                        return valid;
                }       
        } else {
                frm.cust_bstate.value == 'XX';
        }
        if (frm.cust_bzip.value == "") {
                alert("Please enter a zip code!");
                frm.cust_bzip.focus();
                valid = false;
                return valid;
        }               
        if (frm.cust_bphone.value == "") {
                alert("Please enter your phone number!");
                frm.cust_bphone.focus();
                valid = false;
                return valid;
        }               
        if (frm.cust_email.value == "") {
                alert("Please enter your email address!");
                frm.cust_email.focus();
                valid = false;
                return valid;
        }
        if (frm.ship_same.value != 'Y') {
        if (frm.cust_sfname.value == "") {
                alert("Please enter the first name!");
                frm.cust_sfname.focus();
                valid = false;
                return valid;
        }               
        if (frm.cust_slname.value == "") {
                alert("Please enter the last name!");
                frm.cust_slname.focus();
                valid = false;
                return valid;
        }                       
        if (frm.cust_sadd1.value == "") {
                alert("Please enter the address!");
                frm.cust_sadd1.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_scity.value == "") {
                alert("Please enter the city!");
                frm.cust_scity.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_sstate.value == "XX") {
                alert("Please select a state!");
                frm.cust_sstate.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_szip.value == "") {
                alert("Please enter a zip code!");
                frm.cust_szip.focus();
                valid = false;
                return valid;
        }       
                if (frm.cust_sctry.value == 'us') {
                        if (frm.cust_sstate.value == "XX") {
                                alert("Please select a state!");
                                frm.cust_sstate.focus();
                                valid = false;
                                return valid;
                        }       
                } else {
                        frm.cust_sstate.value == 'XX';
                }
        }       
        
        return valid;
                                                                                                                        
}

function validateShipping(frm, loc) {
        var valid = true;
        if (frm.cust_sfname.value == "") {
                alert("Please enter the first name!");
                frm.cust_sfname.focus();
                valid = false;
                return valid;
        }               
        if (frm.cust_slname.value == "") {
                alert("Please enter the last name!");
                frm.cust_slname.focus();
                valid = false;
                return valid;
        }                       
        if (frm.cust_sadd1.value == "") {
                alert("Please enter the address!");
                frm.cust_sadd1.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_scity.value == "") {
                alert("Please enter the city!");
                frm.cust_scity.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_sstate.value == "XX") {
                alert("Please select a state!");
                frm.cust_sstate.focus();
                valid = false;
                return valid;
        }       
        if (frm.cust_szip.value == "") {
                alert("Please enter a zip code!");
                frm.cust_szip.focus();
                valid = false;
                return valid;
        }               


        return valid;
                                                                                                                        
}

function validateState() {
        var valid = true;
                
        if (document.usaForm.cust_bstate.value == 'XX' && document.usaForm.cust_bctry.value == 'us') {
                valid = false;
        } 

        if (valid == false) {
                alert("Please select your state");
                document.usaForm.cust_bstate.focus();
                valid = false;
        }
                        
        return valid;
}

function verifyEmail(email, email2) {
        if (email.value != email2.value) {
                alert("Your email addresses do not match, please re-enter!");
                email.focus();
                return false;
        }
        return true;
}       
