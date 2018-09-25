module StripeMock
  module RequestHandlers
    module ParamValidators

      SUPPORTED_CURRENCIES = ["usd","aed", "afn", "all", "amd", "ang", "aoa", "ars", "aud", "awg", "azn", "bam", "bbd",
                          "bdt", "bgn", "bif", "bmd", "bnd", "bob", "brl", "bsd", "bwp", "bzd", "cad", "cdf", "chf",
                          "clp", "cny", "cop", "crc", "cve", "czk", "djf", "dkk", "dop", "dzd", "egp", "etb", "eur",
                          "fjd", "fkp", "gbp", "gel", "gip", "gmd", "gnf", "gtq", "gyd", "hkd", "hnl", "hrk", "htg",
                          "huf", "idr", "ils", "inr", "isk", "jmd", "jpy", "kes", "kgs", "khr", "kmf", "krw", "kyd",
                          "kzt", "lak", "lbp", "lkr", "lrd", "lsl", "mad", "mdl", "mga", "mkd", "mmk", "mnt", "mop",
                          "mro", "mur", "mvr", "mwk", "mxn", "myr", "mzn", "nad", "ngn", "nio", "nok", "npr", "nzd",
                          "pab", "pen", "pgk", "php", "pkr", "pln", "pyg", "qar", "ron", "rsd", "rub", "rwf", "sar",
                          "sbd", "scr", "sek", "sgd", "shp", "sll", "sos", "srd", "std", "svc", "szl", "thb", "tjs",
                          "top", "try", "ttd", "twd", "tzs", "uah", "ugx", "uyu", "uzs", "vnd", "vuv", "wst", "xaf",
                          "xcd", "xof", "xpf", "yer", "zar", "zmw", "eek", "lvl", "vef"]

      def invalid_currency_message(my_val)
        "Invalid currency: #{my_val.downcase}. Stripe currently supports these currencies: #{SUPPORTED_CURRENCIES.join(", ")}"
      end

      def validate_create_plan_params(params)
        params[:id] = params[:id].to_s

        @base_strategy.create_plan_params.keys.each do |name|
          message =
            if name == :amount
              "Plans require an `#{name}` parameter to be set."
            else
              "Missing required param: #{name}."
            end
          raise Stripe::InvalidRequestError.new(message, name) if params[name].nil?
        end

        if plans[ params[:id] ]
          raise Stripe::InvalidRequestError.new("Plan already exists.", :id)
        end

        unless params[:amount].integer?
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", :amount)
        end
      end

      def validate_create_product_params(params)
        params[:id] = params[:id].to_s

        @base_strategy.create_product_params.keys.reject{ |k,_| k == :id }.each do |k|
          message = "Missing required param: #{k}."
          raise Stripe::InvalidRequestError.new(message, k) if params[k].nil?
        end

        if !["good", "service"].include?(params[:type])
          raise Stripe::InvalidRequestError.new("Invalid type: must be one of good or service", :type)
        end

        if products[ params[:id] ]
          raise Stripe::InvalidRequestError.new("Product already exists.", :id)
        end
      end

    end
  end
end
