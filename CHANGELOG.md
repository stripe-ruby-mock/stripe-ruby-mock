### Unreleased

### 5.0.0
- [#919](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/919) Add capabilities to mock account data [@cazwazacz](https://github.com/cazwazacz)
- [#931](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/931) Support Stripe version 13 + 12 [@gabrieltaylor](https://github.com/gabrieltaylor)

### 4.1.0 (2025-04-24)
- [#920](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/920) Adds DRB as a dependency in preparation to Ruby 3.4.0 [@lucascppessoa](https://github.com/lucascppessoa)
- [#927](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/927) Allow :cancel_url nil in create Checkout Session [@shu-illy](https://github.com/shu-illy)
- [#929](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/929) Actions uses only supported ruby versions [@alexmamonchik](https://github.com/alexmamonchik)
- [#925](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/925) Fix github actions and add missing product attributes [@bettysteger](https://github.com/bettysteger)
- [#928](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/928) Add tax ID endpoints and data [@lfittl](https://github.com/lfittl)
- [#835](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/835) Account: replace deprecated verification hash by requirements [@fabianoarruda](https://github.com/fabianoarruda) 
- [#903](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/903) Add require option to require additional file [@stevenharman](https://github.com/stevenharman)
- [#904](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/904) Add has_more to Subscription.items data [@stevenharman](https://github.com/stevenharman)
- [#843](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/843) Some updates around subscriptions [@donnguyen](https://github.com/donnguyen)
- [#917](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/917) Removed charges on PI and added latest_charge [@espen](https://github.com/espen)
- [#916](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/916) Better tests for payout [@espen](https://github.com/espen) 
- [#862](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/862) Add simple support for us bank accounts [@smtlaissezfaire](https://github.com/smtlaissezfaire)
- [#907](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/907) Fix calls to use raise instead of throw [@smtlaissezfaire](https://github.com/smtlaissezfaire)
- [#908](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/908) Add update_payout [@espen](https://github.com/espen)

### 4.0.0 (2024-08-07)
- [#905](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/905) Allow Stripe SDK v11 by [@stevenharman ](https://github.com/stevenharman)
- [#830](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/830) Implement search API by [@adamstegman](https://github.com/adamstegman)
- [#848](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/848) Extending runtime dependency on Stripe gem from version 5 through 11 by [@smakani](https://github.com/smakani)
- [#893](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/893) Adds support for stripe-ruby v10 by [@fabianoarruda](https://github.com/fabianoarruda)


### 3.1.0 (2024-01-03)
- [#693](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/693) gemspec: add change,issue,source_code URL by [@mtmail](https://github.com/mtmail) 
- [#700](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/700) update the balance API to respond with instant_available by [@iamnader](https://github.com/iamnader) 
- [#687](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/687) Add PaymentIntent Webhooks by [@klaustopher](https://github.com/klaustopher) 
- [#708](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/708) Implement Stripe::Checkout::Session.retrieve by [@coorasse](https://github.com/coorasse) 
- [#711](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/711) Adding account link mock by [@amenon](https://github.com/amenon) 
- [#715](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/715) Added application_fee_amount to mock charge object by [@espen](https://github.com/espen) 
- [#694](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/694) Introduce ideal and sepa_debit types for PaymentMethod by [@mnin](https://github.com/mnin) 
- [#720](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/720) Add additional parameters by [@rpietraszko](https://github.com/rpietraszko)  
- [#695](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/695) Add `has_more` attribute to all ListObject instances by [@gbp](https://github.com/gbp) 
- [#727](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/727) Fix List initialize error with deleted records by [@jmulieri](https://github.com/jmulieri) 
- [#739](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/739) Add data to account links by [@dudyn5ky1](https://github.com/dudyn5ky1)
- [#756](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/756) Added #715 PR to changelog by [@espen](https://github.com/espen) 
- [#759](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/759) Adding express dashboard login link mock by [@rohitbegani](https://github.com/rohitbegani) 
- [#747](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/747) Fix ruby 2.7 deprecation warnings by [@coding-chimp](https://github.com/coding-chimp) 
- [#762](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/762) Support Stripe Connect by adding stripe_account header namespace for customers by [@csalvato](https://github.com/csalvato) 
- [#758](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/758) Create price by [@jamesprior](https://github.com/jamesprior) 
- [#730](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/730) support on price api by [@hidenba](https://github.com/hidenba) 
- [#764](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/764) Fixes erroneous error message when fetching upcoming invoices. by [@csalvato](https://github.com/csalvato) 
- [#765](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/765) Properly set the status of a trialing subscription by [@csalvato](https://github.com/csalvato) 
- [#755](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/755) Add allowed params to subscriptions by [@dominikdarnel](https://github.com/dominikdarnel) 
- [#709](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/709) Remove unnecessary check on customer's currency by [@coorasse](https://github.com/coorasse) 

- [#806](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/806) - Remove `payment_method_types` from required arguments for `Stripe::Checkout::Session`
- [#806](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/806) - Raise more helpful exception when Stripe::Price cannot be found within a `Stripe::Checkout::Session` `line_items` argument.


### 3.1.0.rc3 (pre-release 2021-07-14)

- [#785](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/785): `Stripe::Product` no longer requires `type`. [@TastyPi](https://github.com/TastyPi)
- [#784](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/784): Fix "Wrong number of arguments" error in tests. [@TastyPi](https://github.com/TastyPi)
- [#782](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/782): Support expanding `setup_intent` in `Stripe::Checkout::Session`. [@TastyPi](https://github.com/TastyPi)

### 3.1.0.rc2 (pre-release 2021-03-03)

- [#767](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/767): Fixes tests and more [@lpsBetty](https://github.com/lpsBetty)

### 3.1.0.rc1 (pre-release 2021-02-17)

- [#765](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/765): Properly set the status of a trialing subscription. [@csalvato](https://github.com/csalvato)
- [#764](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/764): Fixes erroneous error message when fetching upcoming invoices. [@csalvato](https://github.com/csalvato)
- [#762](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/762): Support Stripe Connect with Customers by adding stripe_account header namespace for customer object [@csalvato](https://github.com/csalvato)
- [#755](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/755): Add allowed params to subscriptions [@dominikdarnel ](https://github.com/dominikdarnel)
- [#748](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/758): Support Prices - [@hidenba](https://github.com/hidenba) and [@jamesprior](https://github.com/jamesprior).
- [#747](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/747/files): Fix ruby 2.7 deprecation warnings. Adds Ruby 3.0.0 compatibility. [@coding-chimp](https://github.com/coding-chimp)
- [#715](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/715): Added application_fee_amount to mock charge object - [@espen](https://github.com/espen)
- [#709](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/709): Remove unnecessary check on customer's currency - [@coorasse](https://github.com/coorasse)

### 3.0.1 (TBD)

- Added Changelog file
- [#640](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/640): Support Payment Intent status requires_capture - [@theodorton](https://github.com/theodorton).
- [#685](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/685): Adds support for pending_invoice_item_interval - [@joshcass](https://github.com/joshcass).
- [#682](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/682): Prevent customer metadata from being overwritten with each update - [@sethkrasnianski](https://github.com/sethkrasnianski).
- [#679](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/679): Fix for [#678](https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues/678) Add active filter to Data::List - [@rnmp](https://github.com/rnmp).
- [#668](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/668): Fix for [#665](https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues/665) Allow to remove discount from customer - [@mnin](https://github.com/mnin).
- [#667](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/667):
  Remove empty and duplicated methods from payment methods - [@mnin](https://github.com/mnin).
- [#664](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/664): Bugfix: pass through PaymentIntent amount to mocked Charge - [@typeoneerror](https://github.com/typeoneerror).
- [#654](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/654): fix for [#626](https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues/626) Added missing decline codes - [@iCreateJB](https://github.com/iCreateJB).
- [#648](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/648): Initial implementation of checkout session API - [@fauxparse](https://github.com/fauxparse).
- [#644](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/644): Allow payment_behavior attribute on subscription create - [@j15e](https://github.com/j15e).

### 3.0.0 (2019-12-17)

##### the main thing is:

- [#658](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/658) Make the gem compatible with Stripe Gem v.5
