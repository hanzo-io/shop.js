expect = require('chai').expect

describe 'Shop.js', ->
  it 'should start and load all data', ->
    console.log 'This test needs internet access.'

    ret = yield browser.evaluate (key, endpoint)->
      ret = []

      m = Shop.getMediator()

      p = new Promise (resolve, reject)->
        m.one 'started', (data)->
          ret.push
            event:  'started'
            data:   clone(data.get())

          if ret.length == 4
            resolve ret

        m.one 'geo-ready', (geo)->
          ret.push
            event:  'geo-ready'
            geo:    geo
            data:   clone(Shop.data.get())

          if ret.length == 4
            resolve ret

        m.one 'ready', ->
          ret.push { event: 'ready' }

          if ret.length == 4
            resolve ret

        m.one 'async-ready', (constants)->
          ret.push
            event:      'async-ready'
            constants:  constants
            data:       clone(Shop.data.get())

          if ret.length == 4
            resolve ret

      Shop.start
        key:        key
        endpoint:   endpoint

      return p

    , key, endpoint

    # console.log 'returned', ret

    # Default data
    ret.should.not.be.null
    ret.length.should.eq 4
    ret[0].event.should.eq 'started'
    expect(ret[0].data).to.exist

    data = ret[0].data
    data.key.should.eq key
    data.endpoint.should.eq endpoint

    # Populated after AsyncReady
    expect(data.taxRates).to.not.exist
    expect(data.shippingRates).to.not.exist
    data.countries.should.deep.eq []

    # Other default
    data.terms.should.eq false
    expect(data.user).to.not.exist
    expect(data.payment).to.not.exist

    order = data.order
    order.type.should.eq 'stripe'
    order.referrerId.should.eq 'queryRef'

    # Geo is disabled in Electron
    ret[1].event.should.eq 'geo-ready'
    ret[1].geo.status.should.eq 'disabled'

    # Ready to accept commands
    ret[2].event.should.eq 'ready'

    # Loaded data from server
    ret[3].event.should.eq 'async-ready'

    data = ret[3].data

    # Populated after AsyncReady
    expect(data.taxRates).to.exist
    expect(data.shippingRates).to.exist
    data.countries.length.should.eq 247

  it 'should initialize the checkout modal', ->
    console.log 'This test needs internet access and is syncrhonous'

    ret = yield browser.evaluate (key, endpoint)->
      ret = []

      m = Shop.getMediator()
      data = Shop.getData()

      return new Promise (resolve, reject)->
        m.one 'checkout-open', ->
          $userName = $('[id="user.name"]')
            .val 'FirstName LastName'
          $userEmail = $('[id="user.email"]')
            .val 'email@email.com'

          # this should be automatic
          # $paymentAccountName = $('[id="payment.account.name"]')
          #   .val 'FirstName LastName'
          $paymentAccountNumber = $('[id="payment.account.number"]')
            .val '4242 4242 4242 4242'
          $paymentAccountExpiry = $('[id="payment.account.expiry"]')
            .val '04 / 24'
          $paymentAccountCVC = $('[id="payment.account.cvc"]')
            .val '424'

          fireEvent($userName[0], 'change')
          fireEvent($userEmail[0], 'change')
          # fireEvent($paymentAccountName[0], 'change')
          fireEvent($paymentAccountNumber[0], 'change')
          fireEvent($paymentAccountExpiry[0], 'change')
          fireEvent($paymentAccountCVC[0], 'change')

          setTimeout ->
            $('.checkout-next').click()
          , 1000

        m.one 'submit-card', ->
          $shippingAddressLine1 = $('id=["order.shippingAddress.line1"]')
            .val '405 Southwest Blvd'
          $shippingAddressLine2 = $('id=["order.shippingAddress.line2"]')
            .val '#200'


        m.one 'submit-success', ->
          resolve true

        # start
        m.trigger 'checkout-open'

    ret.should.be.true
