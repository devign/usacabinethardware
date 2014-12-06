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
 #       $ON_discount_mult = .05;    
    } elsif ($sub_total >= 1500 && $sub_total < 2000) { 
        $ON_discount_mult = .05;     
    } elsif ($sub_total >= 2000 && $sub_total < 3000) {  
        $ON_discount_mult = .075;    
    } elsif ($sub_total >= 3000) {
        $ON_discount_mult = .125;    
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
    
#    if ($existing_discount > 0) {
#        $ON_discount = 0;
#    }
    
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
    $total_weight += 1 if ($total_weight < 1);
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
    $ship_rate += 1;
        
    if ($ship_rate > 0 && $ship_rate < 6) {
        $ship_rate = 6.68;
    } 

    if ($order_total < 25) {
        $ship_rate += 1;
    }
  
    if ($ship_method eq 'GROUND' && $order_total > 77 && $total_weight < 25) { 
        $ship_rate = 0;
    } elsif ($ship_method eq 'GROUND' && $order_total > 100 && $total_weight < 40) {
        $ship_rate = $ship_rate * .6;
    } elsif ($ship_method eq 'GROUND' && $order_total > 500 && $total_weight < 75) {
        $ship_rate = $ship_rate * .35;
    } elsif ($ship_method eq 'GROUND' && $order_total > 750 && $total_weight < 100) {
        $ship_rate = 0;
    } elsif ($ship_method eq 'GROUND' && $order_total > 1000) {
        $ship_rate = 0;
    } 
    
    if ($ship_method ne 'GROUND') {
        $ship_rate += 3;
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
                                                
    $ship_rate += 5;
               
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
############################# CREATE CRITERIA LIST ##############################
sub create_criteria_list() {
    if ($form{bid} ne '' || $form{finish} ne '' || $form{size} ne '') {
       
        print qq^<div class="subHeader2" style="font-size:9pt">^;
        
        if ($form{bid} ne '') {
            my $brand = $DB_edirect->selectrow_array("SELECT brand FROM brands
                                                      WHERE brand_id = '$form{bid}'");

            my $remove_url = $cgi_url . 'usastore.pl?a=b&cnid=' . $form{cnid} . 
                    '&finish=' . $form{finish} . '&size=' . $form{size};

            $remove_url = &url_encode("$remove_url");                                           
            print qq^BRAND: <span>$brand</span> <a href="$remove_url">
                      <img class="buttonRemove" src="${img_url}button-remove.gif" alt="remove brand" title="remove brand"></a>^;
                      
        }
        
        if ($form{finish} ne '') {
            my $remove_url = $cgi_url . 'usastore.pl?a=b&cnid=' . $form{cnid} . '&bid=' . 
                          $form{bid} . '&size=' . $form{size};
            $remove_url = &url_encode("$remove_url");               
            print qq^FINISH: <span>$form{finish}</span> <a href="$remove_url">
                      <img class="buttonRemove" src="${img_url}button-remove.gif" alt="remove finish" title="remove finish"></a>^;
        }
        
        if ($form{size}) {
            $form{size} =~ s/in/\"/;
            my $remove_url = $cgi_url . 'usastore.pl?a=b&cnid=' . $form{cnid} . '&bid=' . 
                          $form{bid} . '&finish=' . $form{finish};
            $remove_url = &url_encode("$remove_url");              
            print qq^SIZE: <span>$form{size}</span> <a href="$remove_url">
                      <img class="buttonRemove" src="${img_url}button-remove.gif" alt="remove size" title="remove size"></a>^;
        }
        
        print qq^</div>^;
    }    
}
#################################################################################
#################################################################################

#################################################################################
########################## CREATE HELP NAVIGATION  #############################
sub create_help_nav() {
    my $aisle_id = shift;
    
    if (length($aisle_id) > 4) {
        $aisle_id = $DB_edirect->selectrow_array("SELECT aisle_id FROM store_sections
                                                 WHERE section_id = '$form{cnid}'");
    } 
    
    print qq^<div id="helpNav">
              <div style="margin-left:17px;margin-bottom:20px">
                  <div>
                  <img src="${img_url}/why-buy-from.jpg">
                  </div>
                  <div style="padding-bottom:5px">
                  <img src="${img_url}reasons-to-buy-exp.jpg" alt="17 years experience in hardware, online since 2002">
                  </div>
                  <div style="padding-bottom:5px">
                  <a href="${base_url}policies.html"><img border="0" src="${img_url}reasons-to-buy-shipping.jpg" alt="free ground shipping on orders over 77"></a>
                  </div>
                  <div style="padding-bottom:5px">
                  <img src="${img_url}reasons-to-buy-pricing.jpg" alt="We don't play pricing games">
                  </div>
                  <div style="padding-bottom:5px">
                  <img src="${img_url}reasons-to-buy-safe.jpg" alt="Safe, secure, private online shopping">
                  </div>
                  <div style="padding-bottom:5px">
				          <a href="${base_url}policies.html"><img border="0" src="${img_url}reasons-to-buy-returns.jpg" alt="EZ-returns - Click For Full Return Policy" title="Click To Read Return Policy"></a>
                  </div>
               </div>^;
               
    if ($aisle_id == 3800) {
        print qq^
                <div class="sectionHead"> Search For Knobs - Pulls - Backplates</div>
                <div class="sectionMain">
                <ul style="padding-top:10px">
                <li style="padding-bottom:10px">
                <a href="${cgi_url}usacollect.pl?st=1&bid=639"><b>Decorative Hardware Collections</b></a><br>
                <div class=small>Find your hardware by visually searching through the brands and collections
                of your choice. </div></li>
                <li style="padding-bottom:10px">
                <a href="${cgi_url}usastore.pl?a=cs&t=knobSearch"><b>Selective Cabinet Knob Search</b></a><br>
                <div class=small>Search our database of decorative cabinet hardware by
                selecting from existing terms.</div></li>
                <li>
                <a href="${base_url}search.html"><b>Cabinet Knob Keyword Search</b></a><br>
                <div class=small>Enter a product number, finish type or description     
                to perform your own search.</div></li>
                </ul>
                </div>
                <br><br>
                
              <div class="sectionHead"> Decorative Hardware Resource</div>
              <div class="sectionMain">
                <ul style="padding-top:10px">
                <li style="padding-bottom:10px">
                <a href="${base_url}knob-and-pull-terms.html"><b>Terms & Abbreviations</b></a>
                <div class=small>Get the low-down on the lingo in the cabinet hardware 
                circle.  </div></li>
                <li style="padding-bottom:10px">
                <a href="${base_url}hardware-install-tips.pdf"><b>Installation/Replacement</b></a>
                <div class=small>How to measure existing knobs, handles or backplates...
                what to do if you can't find hardware for odd size... 
                </div></li>
                <li>
                <a href="${base_url}knob-and-pull-faq.html"><b>Decorative Knob & Pull FAQ </b></a>
                <div class=small>Some frequently asked questions (and answers!) 
                regarding decorative cabinet hardware. 
                </div></li>
                </ul>
                 </div>
                 </div>^;
    } elsif ($aisle_id == 3801) {
        print qq^
                <div class="sectionHead"> Search Cabinet Hinges</div>
                <div class="sectionMain">
                <ul style="padding-top:10px">
                <li style="padding-bottom:10px">
                <a href="${cgi_url}usastore.pl?a=cs&t=hingeSearch"><b>Selective Cabinet Hinge Search</b></a><br>
                <div class=small>Search our database of cabinet hignes and accessories by
                selecting from existing terms.</div></li>
                <li>
                <a href="${base_url}search.html"><b>Cabinet Hinge Keyword Search</b></a><br>
                <div class=small>Enter a product number, finish type or description     
                to perform your own search.</div></li>
                </ul>
                </div>
                <br><br>
        
                <div class="sectionHead">Cabinet Hinge Reference</div>
                <div class="sectionMain">
                <ul>
                <li>
                <a href="${base_url}cabinet-hinge-terms.html"><b>Cabinet Hinge Terms</b></a>
                <div class=small>Get the low-down on the lingo in the functional 
                        cabinet hardware circle.  
						    </div>
						    </li>
				        <li>
                <a href="${base_url}cabinet-hinge-faq.html"><b>Cabinet Hinge FAQ</b></a>
                <div class=small>Some frequently asked questions (and answers!) 
                        about cabinet hinges. 
                </div>
				        </li>
				        <li>
                <a href="${base_url}hinge-howto.html"><b>Cabinet Hinge How-To</b></a>
                <div class=small>Get some help identifying the type and/or size
				        of your cabinet hinges. 
                </div>
				        </li>
				        <li>
                <a href="${base_url}hinge-howto-vid.html"><b>Cabinet Hinge How-To Videos</b></a>
                <div class=small>Watch these videos for more help identifying the type and/or size
				        of your cabinet hinges . 
                </div>
				        </li>
				        <li>
                <a href="${base_url}hinge-help.html"><b>Cabinet Hinge Help</b></a>
                <div class=small>Get some help replacing cabinet hinges and/or 
				        mounting plates. 
                </div>
				        </li>
 <!--           <li>
                <a href="${base_url}cabinet-hinge-styles.html"><b>Cabinet Hinge Styles</b></a>
                <div class=small>Learn about the different styles of cabinet hinges.
                </div></li>
        -->             
                <li>
                <a href="${base_url}blum-hinges.html"><b>Blum Concealed Hinge Program</b></a>
                <div class=small>All about the Blum European style concealed hinges
                and mounting plates.
                </div>
				        </li>
				        <li>
                <a href="${base_url}grass-hinges.html"><b>Grass Concealed Hinge Program</b></a>
                <div class=small>Learn more about the Grass series of European
				style concealed cabinet hinges and baseplates.
                </div>
				        </li>
                
                </ul>
                </div>
                </div>^;
     } elsif ($aisle_id == 3802) {
        print qq^
                <div class="sectionHead">Search For Drawer Slides</div>
                <div class="sectionMain">
                <ul>
                <li>              
                <a href="${cgi_url}usastore.pl?a=cs&t=slideSearch"><b>Cabinet Drawer Slide Search</b></a>
                <div class=small>Search our database of cabinet drawer slides by
                selecting from existing terms.</div></li>
                <li>
                <a href="${base_url}search.html"><b>Drawer Slide Keyword Search</b></a>
                <div class=small>Enter a product number, type or description    
                to perform your own search.</div></li>
                </ul>
                </div>
        <br><br>
              <div class="sectionHead">Drawer Slide Reference</div>
              <div class="sectionMain">
                <ul>
                <li>
        <a href="${base_url}drawer-slide-terms.html"><b>Drawer Slide Terms</b></a>
                <div class=small>Get the low-down on the lingo in the functional cabinet 
                hardware circle.  </div></li>
        <!--            
                <li>
                <a href="${base_url}drawer-slide-styles.html"><b>Drawer Slide Styles</b></a>
                <div class=small>Learn about the different styles of cabinet
                        and furniture drawer slides.
                </div></li>
        -->      
                <li>
                <a href="${base_url}docs/specs/pdf/643/AC-SLIDE-REFERENCE-GUIDE.pdf"><b>Accuride Reference Guide</b></a> (PDF)
                <div class=small>Get a quick overview of the Accuride family of
                cabinet drawer slides.
                </div></li>       
                <li>
                <a href="${base_url}blum-tandem.pdf"><b>Blum Tandem Drawer Slide</b></a> (PDF)
                <div class=small>All about the Blum Tandem line of cabinet
                        drawer slides.
                </div></li>
                <li>
                <a href="${base_url}blum-solo.pdf"><b>Blum SOLO Drawer Slide</b></a> (PDF)
                <div class=small>All about the Blum SOLO line of cabinet
                        drawer slides.
                </div></li>
                <li>
                <a href="${base_url}docs/specs/pdf/641/KV-DRAWER-SLIDE-APP-GUIDE.pdf"><b>KV Slide Application Chart</b></a> (PDF)
                <div class=small>A quick guide to the applications and raings
                of Knape & Vogt drawer slides.
                </div></li>
                <li>
                <a href="${base_url}drawer-slide-faq.html"><b>Drawer Slide FAQ</b></a>
                <div class=small>Some frequently asked questions (and answers!) 
                about drawer slides. 
                </div></li>
                </ul>
                </div>
                </div>^;
    } else {
        print qq^
                <div class="sectionHead">Search For Knobs - Pulls - Backplates</div>
                <div class="sectionMain">
                <ul style="padding-top:10px">
                <li style="padding-bottom:10px">
                <a href="${cgi_url}usacollect.pl?st=1&bid=639"><b>Decorative Hardware Collections</b></a><br>
                <div class=small>Find your hardware by visually searching through the brands and collections
                of your choice. </div></li>
                <li style="padding-bottom:10px">
                <a href="${cgi_url}usastore.pl?a=cs&t=knobSearch"><b>Selective Cabinet Knob Search</b></a><br>
                <div class=small>Search our database of decorative cabinet hardware by
                selecting from existing terms.</div></li>
                </ul>
                </div>
                <br><br>
                
              <div class="sectionHead">Decorative Hardware Reference</div>
              <div class="sectionMain">
                <ul style="padding-top:10px">
                <li style="padding-bottom:10px">
                <a href="${base_url}knob-and-pull-terms.html"><b>Terms & Abbreviations</b></a>
                <div class=small>Get the low-down on the lingo in the cabinet hardware 
                circle.  </div></li>
                <li style="padding-bottom:10px">
                <a href="${base_url}hardware-install-tips.pdf"><b>Installation/Replacement</b></a>
                <div class=small>How to measure existing knobs, handles or backplates...
                what to do if you can't find hardware for odd size... 
                </div></li>
                <li>
                <a href="${base_url}knob-and-pull-faq.html"><b>Decorative Knob & Pull FAQ </b></a>
                <div class=small>Some frequently asked questions (and answers!) 
                regarding decorative cabinet hardware. 
                </div></li>
                </ul>
                 </div><br><br>
                 ^;      
    
        print qq^
                <div class="sectionHead">Search Cabinet Hinges</div>
                <div class="sectionMain">
                <ul style="padding-top:10px">
                <li style="padding-bottom:10px">
                <a href="${cgi_url}usastore.pl?a=cs&t=hingeSearch"><b>Selective Cabinet Hinge Search</b></a><br>
                <div class=small>Search our database of cabinet hignes and accessories by
                selecting from existing terms.</div></li>
                </ul>
                </div>
                <br><br>
        
                <div class="sectionHead">Cabinet Hinge Reference</div>
                <div class="sectionMain">
                <ul>
                <li>
                <a href="${base_url}cabinet-hinge-terms.html"><b>Cabinet Hinge Terms</b></a>
                <div class=small>Get the low-down on the lingo in the functional 
                        cabinet hardware circle.  
						    </div>
						    </li>
				        <li>
                <a href="${base_url}cabinet-hinge-faq.html"><b>Cabinet Hinge FAQ</b></a>
                <div class=small>Some frequently asked questions (and answers!) 
                        about cabinet hinges. 
                </div>
				        </li>
				        <li>
                <a href="${base_url}hinge-howto.html"><b>Cabinet Hinge How-To</b></a>
                <div class=small>Get some help identifying the type and/or size
				        of your cabinet hinges. 
                </div>
				        </li>
				        <li>
                <a href="${base_url}hinge-howto-vid.html"><b>Cabinet Hinge How-To Videos</b></a>
                <div class=small>Watch these videos for more help identifying the type and/or size
				        of your cabinet hinges . 
                </div>
				        </li>
				        <li>
                <a href="${base_url}hinge-help.html"><b>Cabinet Hinge Help</b></a>
                <div class=small>Get some help replacing cabinet hinges and/or 
				        mounting plates. 
                </div>
				        </li>
 <!--           <li>
                <a href="${base_url}cabinet-hinge-styles.html"><b>Cabinet Hinge Styles</b></a>
                <div class=small>Learn about the different styles of cabinet hinges.
                </div></li>
        -->             
                <li>
                <a href="${base_url}blum-hinges.html"><b>Blum Concealed Hinge Program</b></a>
                <div class=small>All about the Blum European style concealed hinges
                and mounting plates.
                </div>
				        </li>
				        <li>
                <a href="${base_url}grass-hinges.html"><b>Grass Concealed Hinge Program</b></a>
                <div class=small>Learn more about the Grass series of European
				style concealed cabinet hinges and baseplates.
                </div>
				        </li>
                
                </ul>
                </div>
                </div>^;
    }
                    
}
######################## END CREATE HELP NAVIGATION  ############################
#################################################################################

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

#################################################################################
########################## CREATE SIDE NAVIGATION BOXES #########################
sub create_side_nav() {
    my $cnid = shift;
    my $db_query;
    
    if (length($cnid) == 4) {
      ###GET SECTIONS
        $ST_DB = $DB_edirect->prepare("SELECT DISTINCT sss.section_id, section_name 
                                      FROM store_shelves ss, store_sections sss
                                      WHERE ss.section_id = sss.section_id
                                      and sss.aisle_id = '$cnid'");
        $ST_DB->execute();
        $sections = $ST_DB->fetchall_arrayref();

        if (!exists($form{bid}) || $form{bid} eq '') {
        
          ###GET BRANDS
            $db_query = "SELECT DISTINCT b.brand_id, brand 
                                          FROM brands b, products p, prod_to_store pts, store_shelves ss, store_sections sss
                                          WHERE b.brand_id = p.brand_id
                                          and p.prod_id = pts.prod_id
                                          and pts.shelf_id = ss.shelf_id
                                          and ss.section_id = sss.section_id
                                          and sss.aisle_id = '$cnid'";
            
            if (exists($form{finish}) && $form{finish} ne '') {
                $db_query .= " and finish = '$form{finish}'";
            }
            
            if (exists($form{size}) && $form{size} ne '' ) {
                $form{size} =~ s/in/\"/;
                $db_query .= " and size1 = '$form{size}'";
            }
            
            $db_query .= " ORDER BY brand ASC";
            
            $ST_DB = $DB_edirect->prepare("$db_query");
            $ST_DB->execute();
            $brands = $ST_DB->fetchall_arrayref();
            $ST_DB->finish();
        }
        
        if (!exists($form{size}) || $form{size} eq '') {
          ###GET SIZES  
            $db_query = "SELECT count(p.prod_id), size1  
                                          FROM products p, prod_to_store pts, store_shelves ss, store_sections sss
                                          WHERE p.prod_id = pts.prod_id
                                          and pts.shelf_id = ss.shelf_id
                                          and ss.section_id = sss.section_id
                                          and sss.aisle_id = '$cnid'
                                          and size1 IS NOT NULL";

            if (exists($form{bid}) && $form{bid} ne '') {
                $db_query .= " and brand_id = '$form{bid}'";
            }
            
            if (exists($form{finish}) && $form{finish} ne '' ) {
                $db_query .= " and finish = '$form{finish}'";
            }
            
            $db_query .= " GROUP BY size1
                           ORDER BY size1 ASC";
            
            $ST_DB = $DB_edirect->prepare("$db_query");               
            $ST_DB->execute();
            $sizes = $ST_DB->fetchall_arrayref(); 
            $ST_DB->finish();       
        }

        if (!exists($form{finish}) || $form{finish} eq '') {           
          ###GET FINiSHES  
            $db_query = "SELECT count(p.prod_id), finish 
                                          FROM products p, prod_to_store pts, store_shelves ss, store_sections sss
                                          WHERE p.prod_id = pts.prod_id
                                          and pts.shelf_id = ss.shelf_id
                                          and ss.section_id = sss.section_id
                                          and sss.aisle_id = '$cnid'";

            if (exists($form{bid}) && $form{bid} ne '') {
                $db_query .= " and brand_id = '$form{bid}'";
            }
    
            if (exists($form{size}) && $form{size} ne '' ) {
                 $form{size} =~ s/in/\"/;
                  $db_query .= " and size1 = '$form{size}'";
            }
            
            $db_query .= " GROUP BY finish
                           ORDER BY finish ASC";
            
            $ST_DB = $DB_edirect->prepare("$db_query");                             
            $ST_DB->execute();
            $finishes = $ST_DB->fetchall_arrayref();  
            $ST_DB->finish();
        }

    
    } elsif (length($cnid) == 5) {

        if (!exists($form{bid}) || $form{bid} eq '') {            
          ###GET BRANDS
            $db_query = "SELECT DISTINCT b.brand_id, brand 
                                          FROM brands b, products p, prod_to_store pts, store_shelves ss
                                          WHERE b.brand_id = p.brand_id
                                          and p.prod_id = pts.prod_id
                                          and pts.shelf_id = ss.shelf_id
                                          and ss.section_id = '$cnid'";
                                          
            if (exists($form{finish}) && $form{finish} ne '') {
                $db_query .= " and finish = '$form{finish}'";
            }
            
            if (exists($form{size}) && $form{size} ne '' ) {
                $form{size} =~ s/in/\"/;
                $db_query .= " and size1 = '$form{size}'";
            }
        
            $db_query .= " ORDER BY brand ASC";
    
            $ST_DB = $DB_edirect->prepare("$db_query");
            $ST_DB->execute();
            $brands = $ST_DB->fetchall_arrayref();
            $ST_DB->finish();
        }
        
        if (!exists($form{size}) || $form{size} eq '') {
          ###GET SIZES  
            $db_query = "SELECT count(p.prod_id), size1 
                                          FROM products p, prod_to_store pts, store_shelves ss
                                          WHERE p.prod_id = pts.prod_id
                                          and pts.shelf_id = ss.shelf_id
                                          and ss.section_id = '$cnid'
                                          and size1 IS NOT NULL";
                                          
            if (exists($form{bid}) && $form{bid} ne '') {
                $db_query .= " and brand_id = '$form{bid}'";
            }
            
            if (exists($form{finish}) && $form{finish} ne '' ) {
                $db_query .= " and finish = '$form{finish}'";
            }
            
            $db_query .=  " GROUP BY size1
                            ORDER BY size1 ASC";
            
            $ST_DB = $DB_edirect->prepare("$db_query");                
            $ST_DB->execute();
            $sizes = $ST_DB->fetchall_arrayref();   
            $ST_DB->finish();    
        }
        
        if (!exists($form{finish}) || $form{finish} eq '') {          
          ###GET FINiSHES  
            $db_query = "SELECT count(p.prod_id), finish 
                                          FROM products p, prod_to_store pts, store_shelves ss
                                          WHERE p.prod_id = pts.prod_id
                                          and pts.shelf_id = ss.shelf_id
                                          and ss.section_id = '$cnid'";
            
            if (exists($form{bid}) && $form{bid} ne '') {
                $db_query .= " and brand_id = '$form{bid}'";
            }
    
            if (exists($form{size}) && $form{size} ne '' ) {
                 $form{size} =~ s/in/\"/;
                  $db_query .= " and size1 = '$form{size}'";
            }
                        
            $db_query .= " GROUP BY finish
                           ORDER BY finish ASC";
            
            $ST_DB = $DB_edirect->prepare("$db_query");                 
            $ST_DB->execute();
            $finishes = $ST_DB->fetchall_arrayref();  
            $ST_DB->finish();
        }
        
        
    }
    
    
    if ($cnid) {
    
        print qq^<div id="catalogSideNav">^;
        
       
        if (@$sections) {
            print qq^<div class="head">Sub-Categories</div>
                        <div class="section" style="height:auto"><ul>^;
            
            foreach my $section (@$sections) {
                my $link_url = $cgi_url . "usastore.pl?a=b&cnid=@$section[0]&bid=$form{bid}&size=$form{size}&finish=$form{finish}";
                $link_url = &url_encode("$link_url");
                print qq^<li style="font-size:10pt"><a href="$link_url">@$section[1]</a></li>^;
            }
            
            print "</ul></div>";
        } 
            
       
        if (@$brands) {
            print qq^<div class="head">Brands</div>
                        <div class="section" style="height:auto"><ul style="text-align:center">^;
                        
            my $link_url = $cgi_url . 'usastore.pl?a=b&cnid=' . $cnid;
                                
            if (exists($form{size}) && $form{size} ne '') {
                $link_url .= '&size=' . $form{size};
            }
            
            if (exists($form{finish}) && $form{finish} ne '') {
                $link_url .= '&finish=' . $form{finish};
            }
            
            $link_url = &url_encode("$link_url");
                    
            foreach my $brand (@$brands) {
                if (@$brand[0] == $form{bid}) {
                    print qq^<li><strong>@$brand[1]</strong></li>^;
                } else {
                     if (-e "${home_dir}/img/@$brand[0]-logo-tiny.gif") {
                        print qq^<li><a href="${link_url}&bid=@$brand[0]"><img border=0 src="${img_url}@$brand[0]-logo-tiny.gif"></a></li>^;
                     } else {
                        print qq^<li><a href="${link_url}&bid=@$brand[0]">@$brand[1]</a></li>^;
                     }
                }
            }
            
            print "</ul></div>";
        }   
    
        if (@$sizes) {
            print qq^<div class="head">Sizes</div>
                        <div class="section"><ul>^;

            my $link_url = $cgi_url . 'usastore.pl?a=b&cnid=' . $cnid;
            
            if (exists($form{bid}) && $form{bid} ne '') {
                $link_url .= '&bid=' . $form{bid};
            }
            
            if (exists($form{finish}) && $form{finish} ne '') {
                $link_url .= '&finish=' . $form{finish};
            }
            
 #            if (@$sizes > 40) { 
 #               foreach $size (@$sizes) {
 #                   my $size_url_text = @$size[1];
 #                   $size_url_text =~ s/\"/in/;
 #                   if (length($cnid) == 5 && @$size[0] > 50) {
 #                       print qq^<li><a href="${link_url}&size=$size_url_text">@$size[1]</a></li>^;
 #                   } elsif (length($cnid) == 4 && @$size[0] > 100) {
 #                       print qq^<li><a href="${link_url}&size=$size_url_text">@$size[1]</a></li>^;
 #                   }
 #               }
 #           } elsif (@$sizes > 20) { 
 #               foreach $size (@$sizes) {
 #                   my $size_url_text = @$size[1];
 #                   $size_url_text =~ s/\"/in/;
 #                   if (length($cnid) == 5 && @$size[0] > 30) {
 #                       print qq^<li><a href="${link_url}&size=$size_url_text">@$size[1]</a></li>^;
 #                   } elsif (length($cnid) == 4 && @$size[0] > 75) {
 #                       print qq^<li><a href="${link_url}&size=$size_url_text">@$size[1]</a></li>^;
 #                   }
 #               }
 #           } else {
             $link_url .= '&size=';
             foreach $size (@$sizes) {
                my $this_link_url = $link_url;
                $this_link_url .= @$size[1];
                $this_link_url = &url_encode("$this_link_url");
                print qq^<li style="font-size:10pt"><a href="${this_link_url}">@$size[1]</a></li>^;
                    
             }
 #           }
            print "</ul></div>";
            
     #       print qq^</ul></div><div class="moreLink"><a href="#" onClick="document.getElementById('catalogSideNavMoreSizes').style.display='block'">more sizes</div>
     #               <div id="catalogSideNavMoreSizes"><div class="catalogSideNavMoreColumn">^;
            
     #       my $count == 1;        
     #       foreach $size (@$sizes) {
     #            print qq^<a href="${link_url}&size=@$size[0]">@$size[0]</a><br>^;
     #            $count++;
     #            if ($count == 20) {
     #               print qq^</div><div class="catalogSideNavMoreColumn">^;
     #               $count = 1;
     #            }
     #       }
            
      #      print qq^</div></div>^;
        }     
               
        if (@$finishes) {
            print qq^<div class="head">Finishes</div>
                        <div class="section"><ul style="font-size:10pt">^;

            my $link_url = $cgi_url . 'usastore.pl?a=b&cnid=' . $cnid;
                    
            if (exists($form{bid}) && $form{bid} ne '') {
                $link_url .= '&bid=' . $form{bid};
            }
            
            if (exists($form{size}) && $form{size} ne '') {
                $link_url .= '&size=' . $form{size};
            }
                    
 #           if (@$finishes > 40) { 
 #               foreach $finish (@$finishes) {
 #                   if (length($cnid) == 5 && @$finish[0] > 100) {
 #                       print qq^<li><a href="${link_url}&finish=@$finish[1]">@$finish[1]</a></li>^;
 #                   } elsif (length($cnid) == 4 && @$finish[0] > 150) {
 #                       print qq^<li><a href="${link_url}&finish=@$finish[1]">@$finish[1]</a></li>^;
 #                   }
 #               }
 #           } elsif (@$finishes > 20) { 
 #               foreach $finish (@$finishes) {
 #                   if (length($cnid) == 5 && @$finish[0] > 50) {
 #                       print qq^<li><a href="${link_url}&finish=@$finish[1]">@$finish[1]</a></li>^;
 #                   } elsif (length($cnid) == 4 && @$finish[0] > 100) {
 #                       print qq^<li><a href="${link_url}&finish=@$finish[1]">@$finish[1]</a></li>^;
 #                   }
 #               }
 #           } else {
 
             $link_url .= '&finish=';
             foreach $finish (@$finishes) {
                my $this_link_url = $link_url;
                $this_link_url .= @$finish[1];
                $this_link_url = &url_encode("$this_link_url");
                print qq^<li style="font-size:10pt"><a href="${this_link_url}">@$finish[1]</a></li>^;
                    
             }
  #          }
            
            print "</ul></div>";
        }   
    
        print "</div>";
    
    } else {
        my ($aisles, $sections);
        
        $ST_DB = $DB_edirect->prepare("SELECT aisle_id, aisle_name
                                       FROM store_aisles
                                       WHERE dept_id = 240");
        $ST_DB->execute();
        $aisles = $ST_DB->fetchall_arrayref();
        
        print qq^<div id="catalogSideNav"><div class="head">All Categories</div>
                        <div class="section" style="height:auto"><br><ul style="font-size:10pt">^;
        
        foreach $aisle (@$aisles) {
            $ST_DB = $DB_edirect->prepare("SELECT section_id, section_name
                                           FROM store_sections
                                           WHERE aisle_id = @$aisle[0]");
            $ST_DB->execute();
            $sections = $ST_DB->fetchall_arrayref();
            
            print qq^<li><a href="${cgi_url}usastore.pl?a=b&cnid=@$aisle[0]&bid=$form{bid}&size=$form{size}&finish=$form{finish}">@$aisle[1]</a></li><ul>^;
            
            foreach $section (@$sections) {
                print qq^<li><a href="${cgi_url}usastore.pl?a=b&cnid=@$section[0]">@$section[1]</a></li>^;
            }
            
            print "</ul><br><br>";
            
        }
        
        print qq^</ul></div></div>^;
        
        $ST_DB->finish();
        
    }                                                        
                                               
}
######################## END CREATE SIDE NAVIGATION  ##3#########################
#################################################################################   

################################################################################ 
############ BOUGHT THIS ITEM ALSO BOUGHT SUBROUTINE ###########################
sub cust_also_bought() {
    my ($pid, @pids, $inv_nos);
    $pid = shift();
    
    $ST_DB = $DB_edirect->prepare("SELECT inv_no FROM order_details WHERE prod_id = '$pid'");
    $ST_DB->execute();
    $inv_nos = $ST_DB->fetchall_arrayref();
    $ST_DB->finish(); 
        
    if (@$inv_nos != 0) {
        foreach my $inv_no (@$inv_nos) {
            $ST_DB = $DB_edirect->prepare("SELECT prod_id FROM order_details 
                                          WHERE inv_no = @$inv_no 
                                          and prod_id != '$pid'
                                          ORDER BY RAND()");
            $ST_DB->execute();
            my $items = $ST_DB->fetchall_arrayref();
            foreach my $item (@$items) {
                my $item_check = $DB2_edirect->selectrow_array("SELECT count(*) FROM products
                                                                WHERE prod_id = '@$item[0]'");
                my $pid_exists = 0;
                if ($item_check != 0) {  
                    foreach $pid (@pids) {
                        if (@$item[0] eq $pid) {
                            $pid_exists = 1;
                        }
                    }
                    
                    if ($pid_exists == 0) {
                        push @pids, @$item[0];
                        $prod_id_save = @$item[0];
                    } 
                }
            }
            $ST_DB->finish(); 
        }  

    }
    
       
    
    if (@pids > 5) {
        @pids = splice(@pids, 0, 5);
    }

    return @pids;
}
######################### END SUB cust_also_bought #############################
################################################################################     

###############################################################################
############################# SEND EMAIL SUBROUTINE ###########################
sub email_send() {
    use Net::SMTP;
    
    my ($SENDTO, $SENDFROM, $SUBJECT, $MESSAGE, $SENDCC) = @_;
    
    my $HOST = '127.0.0.1';
    my $PORT = '9069';
    
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
################################ GET PAGE TITLE ################################
sub get_page_title() {
    my $page_title;
    
    if (exists($form{pid}) && $form{pid} ne '') {
        my $group_id = $DB_edirect->selectrow_array("SELECT group_id FROM products
                                                     WHERE prod_id = '$form{pid}'");
                                                     
        if ($group_id eq '') {
            my ($brand, $model_num, $descp, $size, $finish) =
                $DB_edirect->selectrow_array("SELECT brand, model_num, detail_descp, size1,
                                              finish
                                              FROM brands b, products p
                                              WHERE b.brand_id = p.brand_id
                                              and p.prod_id = '$form{pid}'");
            
            $page_title = $brand . ' ' .$model_num . ' - ' . $finish . ' ' . $descp . ' ' . $size;
        } else {
            my ($brand, $model_num, $descp) =
                $DB_edirect->selectrow_array("SELECT brand, model_num, detail_descp
                                              FROM brands b, products p
                                              WHERE b.brand_id = p.brand_id
                                              and p.prod_id = '$form{pid}'");
            
            $page_title = $brand . ' ' .$model_num . ' - '  . $descp;
        }
    } else {
        $page_title = 'Kitchen Cabinet Knobs - Cabinet Hinges, Drawer Slides : Cabinet Hardware';
    }
    
    return $page_title;
        
}
########################### END GET PAGE TITLE SUB #############################
################################################################################


################################################################################
######################### GET PRODUCT IMAGE SUBROUTINE #########################
# INPUT: (product id, image type requested)
# OUTPUT: (image name, image url)

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
        $next_page_url, $last_page_url, $cont_url);
    
    ($total_item_count, $current_index, $cont_url) = @_;
    
   
  ##DETERMINE & PRINT PAGE CONTINUATION NAVIGATION        
    $cont_url = $cgi_url . 'usastore.pl?a=' . $form{a} if ($cont_url eq '');
        
    if ($form{did}) {
            $cont_url .= '&did=' . $form{did};
    }
    if ($form{cnid}) {
            $cont_url .= '&cnid=' . $form{cnid};
    }    
    if ($form{t}) {
            $cont_url .= '&t=' . $form{t};
    }    
    if ($form{st}) {
            $cont_url .= '&st=' . $form{st};
    }    
    if ($form{finish}) {
            $form{finish} =~ s/\s/+/g;
            $cont_url .= '&finish=' . $form{finish};
    } 
    if ($form{bid}) {
            $cont_url .= '&bid=' . $form{bid};
    }
    if ($form{cid}) {
            $cont_url .= '&cid=' . $form{cid};
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
    
    $cont_url = &url_encode("$cont_url");
                
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
                        <a style="text-decoration:none" href="$previous_page_url">
                          <b>&lt; BACK</b></a></span>
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

        print qq^
                 <span class="continueLastButtonOff">&lt; BACK</span>
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
              <a style="text-decoration:none" href="$next_page_url">NEXT &gt;</a></span>
                  </div>^;
                  
    } else {
        print qq^</div><span class="continueNextButtonOff">NEXT &gt;</span>
                  </div>^;
    }                

  ##END PAGE CONTINUATION NAVIGATION    
}
############################ END page_continuation SUB #########################
################################################################################

###############################################################################
################################ PAGE FOOTER SUBROUTINE #######################
sub page_footer() {
        print qq^	    <div id="pageFooter">

      <div class="pageFooterBox"><span><a href="${base_url}knobs-pulls.phtml">Cabinet Knobs & Pulls</a></span>
 		<ul>
          <li><a href="${cgi_url}usastore.pl?a=b&cnid=66000">Handle Pulls</a></li>
          <li><a href="${cgi_url}usastore.pl?a=b&cnid=66002">Cabinet Knobs</a></li>
          <li><a href="${cgi_url}usastore.pl?a=b&cnid=66001">Cup Pulls</a></li>
          <li><a href="${cgi_url}usastore.pl?a=b&cnid=66006">Bar Pulls</a></li>
          <li><a href="${cgi_url}usastore.pl?a=b&cnid=66007">Appliance Pulls</a></li>
          <li><a href="${cgi_url}usastore.pl?a=b&cnid=66004">Backplates</a></li>
          <li><a href="${cgi_url}usastore.pl?a=b&cnid=66003">Ring, Bail & Pendant</a></li>
          </ul>
	 </div>
   <div class="pageFooterBox"><span><a href="${base_url}hinges.phtml">Cabinet Hinges</a></span>
		<ul>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66020">Inset</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66021">Overlay</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66030">Euro</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66025">Knife</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66024">Concealed</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66028">Semi-Concealed</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66029">Non-Concealed</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66022">Side Mount</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66023">Surface Mount</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66027">Specialty</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66026">Mounting Plates</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66032">Miscellaneous</a></li>
		</ul>
	</div>
    <div class="pageFooterBox"><span><a href="${base_url}drawer-slides.phtml">Drawer Slides</a></span>
		<ul>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66040">3/4 Extension</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66041">Full Extension</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66042">Overtravel</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66044">Side Mount</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66045">Side/Bottom Mount</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66046">Under Mount</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66047">Flat Mount</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66043">Specialty</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66048">Miscellaneous</a></li>
		</ul>
	</div>
    <div class="pageFooterBox"><span><a href="${base_url}catches-locks.phtml">Catches & Locks</a></span>
		<ul>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66060">Magnetic Catches</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66061">Roller Catches</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66062">Mechanical Catches</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66063">Ball & Bullet Catches</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66064">Cam Locks</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66065">Deabolt Locks</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66066">Gang Locks</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66068">Other Locks</a></li>
			<li><a href="${cgi_url}usastore.pl?a=b&cnid=66067">Lock Accessories</a></li>
		</ul>
	</div>
    <div class="pageFooterBox"><span><a href="${base_url}customer-care.html">Customer Care</a></span>
                <ul>
                <li><a href="${base_url}policies.html#returns">Returns</a></li>
                <li><a href="${base_url}policies.html#shipping">Shipping & Handling</a></li>
                <li><a href="${base_url}policies.html#privacy">Privacy & Security</a></li>
                <li><a href="${base_url}contact.html">Contact Us</a></li>
                <li><a href="${base_url}care-faq.html">Customer Care FAQ</a></li>
                </ul>  	
	</div>

	
	
        <div id="copy">
        Copyright &copy; 2012 usacabinethardware.com by Everything Direct Inc.<br>
        1046 39th Ave W<br>
        West Fargo, ND 58078<br>
        1.866-570-3272<br>
        <a href="mailto:webadmin@usacabinethardware.com">webadmin</a>
        </div>
	</div>


<!-- begin olark code --><script type='text/javascript'>/*{literal}<![CDATA[*/window.olark||(function(i){var e=window,h=document,a=e.location.protocol=="https:"?"https:":"http:",g=i.name,b="load";(function(){e[g]=function(){(c.s=c.s||[]).push(arguments)};var c=e[g]._={},f=i.methods.length; while(f--){(function(j){e[g][j]=function(){e[g]("call",j,arguments)}})(i.methods[f])} c.l=i.loader;c.i=arguments.callee;c.f=setTimeout(function(){if(c.f){(new Image).src=a+"//"+c.l.replace(".js",".png")+"&"+escape(e.location.href)}c.f=null},20000);c.p={0:+new Date};c.P=function(j){c.p[j]=new Date-c.p[0]};function d(){c.P(b);e[g](b)}e.addEventListener?e.addEventListener(b,d,false):e.attachEvent("on"+b,d); (function(){function l(j){j="head";return["<",j,"></",j,"><",z,' onl'+'oad="var d=',B,";d.getElementsByTagName('head')[0].",y,"(d.",A,"('script')).",u,"='",a,"//",c.l,"'",'"',"></",z,">"].join("")}var z="body",s=h[z];if(!s){return setTimeout(arguments.callee,100)}c.P(1);var y="appendChild",A="createElement",u="src",r=h[A]("div"),G=r[y](h[A](g)),D=h[A]("iframe"),B="document",C="domain",q;r.style.display="none";s.insertBefore(r,s.firstChild).id=g;D.frameBorder="0";D.id=g+"-loader";if(/MSIE[ ]+6/.test(navigator.userAgent)){D.src="javascript:false"} D.allowTransparency="true";G[y](D);try{D.contentWindow[B].open()}catch(F){i[C]=h[C];q="javascript:var d="+B+".open();d.domain='"+h.domain+"';";D[u]=q+"void(0);"}try{var H=D.contentWindow[B];H.write(l());H.close()}catch(E){D[u]=q+'d.write("'+l().replace(/"/g,String.fromCharCode(92)+'"')+'");d.close();'}c.P(2)})()})()})({loader:(function(a){return "static.olark.com/jsclient/loader0.js?ts="+(a?a[1]:(+new Date))})(document.cookie.match(/olarkld=([0-9]+)/)),name:"olark",methods:["configure","extend","declare","identify"]});
/* custom configuration goes here (www.olark.com/documentation) */
olark.identify('5755-749-10-6075');/*]]>{/literal}*/</script>
<!-- end olark code -->

</body>
</html>
^;
}
############################## END SUB page_footer ############################
###############################################################################

###############################################################################
############################# PAGE HEADER SUBROUTINE ##########################
sub page_header() {
    my $page_title;
    
    if (!$ENV{HTTP_COOKIE} && $session_id) {
            print "Set-cookie:sid=$session_id;domain=$ENV{HTTP_HOST}\n";
    }
    
    if (@_) {
        $page_title =  shift;
    } else {
        $page_title = 'Shop Cabinet Hardware at USACabinetHardware.com';
    }
    
    print "Content-type: text/html\n\n";
    print qq^<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
            <html><head><title>$page_title</title>^;
  
    if ($ENV{HTTP_HOST} eq 'secure.usacabinethardware.com') {
          print qq^                
           <link rel=\"Stylesheet\" type=\"text/css\" href=\"${secure_url}main.css\">
           <SCRIPT SRC=\"${secure_url}usa.js\"></SCRIPT>\n^;
    } else {
          print qq^                
           		

           		<link rel="Stylesheet" type="text/css" href="${base_url}styles/lightbox.css">
           		<link rel="Stylesheet" type="text/css" href="${base_url}main.css?v=2">
				<script src="${base_url}js/jquery-1.7.2.min.js"></script>
  	    		<script src="${base_url}js/jquery-ui-1.8.18.custom.min.js"></script>
  	    		<script src="${base_url}js/jquery.smooth-scroll.min.js"></script>
  	    		<script src="${base_url}lbox/lightbox.js"></script>
           		<script src="${base_url}usa.js"></script>\n ^;
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
            width:300px;
            margin-left: 10px;  
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

    print qq^
    </head><body>
    <!-- Google Tag Manager -->
<noscript><iframe src="//www.googletagmanager.com/ns.html?id=GTM-W2R9"
height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'//www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','GTM-W2R9');</script>
<!-- End Google Tag Manager -->
    
              <div id="pageContainer">
                <div id="pageHead">
            <map name="_head">
            <area shape="rect" coords="91,37,597,81" href="${base_url}index.html" alt="" >
            <area shape="rect" coords="888,71,980,92" href="${base_url}search.html" alt="" >
            <area shape="rect" coords="877,50,980,71" href="${base_url}contact.html" alt="" >
            <area shape="rect" coords="878,27,980,48" href="${cgi_url}usastore.pl?a=cart_display" alt="" >
            <area shape="rect" coords="830,96,980,120" href="${base_url}customer-care.html" alt="" >
            <area shape="rect" coords="558,98,729,126" href="${base_url}catches-locks.phtml" alt="" >
            <area shape="rect" coords="398,96,542,126" href="${base_url}drawer-slides.phtml" alt="" >
            <area shape="rect" coords="303,97,382,126" href="${base_url}hinges.phtml" alt="" >
            <area shape="rect" coords="133,96,288,126" href="${base_url}knobs-pulls.phtml" alt="" >
            <area shape="rect" coords="872,0,980,25" href="${secure_cgi}usastore.pl?a=checkout" alt="" >
            <area shape="rect" coords="339,112,340,113" href="#" alt="" >
            </map><img name="head" src="${img_url}head.jpg" width="980" border="0" usemap="#_head" alt="USA Cabinet Hardware Logo & Navigation">
                </div>^;
        
}
############################# END SUB page_header #############################
###############################################################################

#################################################################################
############################# PAGE FOOTER  SUBROUTINE ###########################
sub page_search_footer() {
        if ($form{t} eq 'knobSearch') {
                $title = 'KNOBS AND PULLS';
        } elsif ($form{t} eq 'hingeSearch') {
                $title = 'HINGES';
        } elsif ($form{t} eq 'slideSearch') {
                $title = 'DRAWER SLIDES';
        } else {
                $title = 'CATCHES AND LOCKS';
        }
        
        print qq^<div style="padding-top:10px;padding-bottom:10px;font-size:10pt;font-weight:bold;text-align:center">^;
        
        if (!$form{user_term}) {
                        print qq^
        <a href="usastore.pl?a=cs&t=$form{t}&bid=$form{bid}&descp=$form{descp}&finish=$form{finish}&cnid=$form{cnid}&size=$form{size}" style="padding-left:15px">ADJUST THIS $title SEARCH</a>^;
        }
        
        print qq^
            <a href="usastore.pl?a=cs&t=$form{t}" style="padding-left:15px">NEW $title SEARCH</a>
            <br>
            <a href="usastore.pl?a=cs&st=1" style="padding-left:15px">NEW SELECTIVE SEARCH</a>
            </div>^;
       
  

} 
########################## END page_footer SUBROUTINE ###########################
#################################################################################

###############################################################################
############################# PAGE SUBHEADER SUBROUTINE ##########################
sub page_subheader() {
    print qq^<div id="subHeaderContainer">^;
    
    if ($form{a} eq 'b') {
        print qq^<div class="subHeader">BROWSE CATALOG ::</div>^;
        if (exists($form{cnid}) && $form{cnid} ne '') {
            print qq^<div class="subHeader">^;
                      
            if (length($form{cnid}) == 5) {
                my ($section_name, $aisle_id, $aisle_name) =  
                      $DB_edirect->selectrow_array("SELECT section_name, a.aisle_id, a.aisle_name
                                                    FROM store_sections s, store_aisles a
                                                    WHERE s.aisle_id = a.aisle_id
                                                    and section_id = '$form{cnid}'");
                print qq^<a href="${cgi_url}usastore.pl?a=b&cnid=${aisle_id}">$aisle_name</a> -> $section_name^;
                
            } else {
                my $aisle_name =  
                      $DB_edirect->selectrow_array("SELECT aisle_name
                                                    FROM store_aisles
                                                    WHERE aisle_id = '$form{cnid}'");
    
                   print qq^$aisle_name^;
            }
            
            print "</div>";
        }
            
        
        if (exists($form{bid}) && $form{bid} ne '') {
            my $brand = $DB_edirect->selectrow_array("SELECT brand FROM brands WHERE brand_id = '$form{bid}'");
            print qq^<div class="subHeader">by $brand</div>^;
        }
    
    } elsif ($form{a} eq 's') {
        print qq^<div class="subHeader">SEARCH CATALOG</div>^;
    } elsif ($form{a} eq 'cs') {
        print qq^<div class="subHeader">SELECTIVE SEARCH^;
       
        if ($form{t} eq 'hingeSearch') {
            print "->Cabinet Hinges";
        } elsif ($form{t} eq 'slideSearch') {
            print "->Drawer Slides";
        } else {
            print "->Cabinet Knobs & Pulls";
        }
       
        print "</div";
       
    } elsif ($form{a} eq 'cart_checkout') {
        print qq^<div class="subHeader">STORE CHECKOUT</div>^;
    } elsif ($form{a} eq 'dc' || $form{a} eq 'cart_clear') {
        print qq^<div class="subHeader">YOUR CART</div>^;
    } 
    
    print qq^<div id="catalogSearch"><form method="post" action="usastore.pl">
              <input type="hidden" name="a" value="cat_search">
              <input style="font-size: 11px" type="text" name="search_value" value="Search Our Catalog" size="30" onFocus="this.value=''">
              <input type="submit" value="SEARCH" class="formButton formButtonSmall">
              </form>
              </div>
              </div>^;
                           
           
}
###############################################################################
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

################################################################################
############################### SUB encode_url #################################
sub url_encode() {
    $_[0] =~ s/\s/%20/g;
    $_[0] =~ s/\"/%22/g;
    
    return $_[0];
}
############################## END SUB encode_url ##############################
################################################################################

1;

