module StripeMock
  module ApiVersions
    module Basil
      VERSION = "2025-03-31".freeze

      def self.tax(amount)
        {
          amount: amount,
          tax_behavior: "exclusive",
          tax_rate_details: nil,
          taxability_reason: nil,
          taxable_amount: nil,
          type: "tax_rate_details"
        }
      end

      def self.pricing(price)
        return nil unless price

        amount = price[:unit_amount] || price[:amount]
        {
          type: "price_details",
          price_details: { price: price[:id], product: price[:product] },
          unit_amount_decimal: amount&.to_s
        }
      end

      def self.discount_ids(object)
        object[:discount] ? [object[:discount][:id]].compact : []
      end

      # https://docs.stripe.com/changelog/basil/2025-03-31/deprecate-subscription-current-period-start-and-end
      class SubscriptionItemPeriods < Change
        applies_to VERSION, "subscription"
        removes :current_period_start, :current_period_end

        def response(subscription)
          (subscription.dig(:items, :data) || []).each do |item|
            item[:current_period_start] ||= subscription[:current_period_start]
            item[:current_period_end] ||= subscription[:current_period_end]
          end
        end
      end

      # https://docs.stripe.com/changelog/basil/2025-03-31/deprecate-singular-coupon-promotion-code
      class SubscriptionDiscounts < Change
        applies_to VERSION, "subscription"
        removes :discount

        def response(subscription)
          subscription[:discounts] ||= Basil.discount_ids(subscription)
        end
      end

      class SubscriptionDiscountsParam < Change
        applies_to VERSION
        params_for :create_subscription, :create_customer_subscription, :update_subscription

        def params(params)
          return params unless params.key?(:discounts)

          discounts = params.delete(:discounts)
          discounts = discounts.values if discounts.respond_to?(:values)
          if discounts.nil? || discounts == "" || discounts.empty?
            params[:coupon] = ""
          else
            discount = discounts.first
            params[:coupon] ||= discount[:coupon] if discount[:coupon]
            params[:promotion_code] ||= discount[:promotion_code] if discount[:promotion_code]
          end
          params
        end
      end

      # https://docs.stripe.com/changelog/basil/2025-03-31/adds-new-parent-field-to-invoicing-objects
      class InvoiceParent < Change
        applies_to VERSION, "invoice"
        removes :subscription, :subscription_details, :quote

        def response(invoice)
          invoice[:parent] ||= invoice[:subscription] && {
            type: "subscription_details",
            quote_details: nil,
            subscription_details: { subscription: invoice[:subscription], metadata: {} }
          }
        end
      end

      class InvoiceDiscounts < Change
        applies_to VERSION, "invoice"
        removes :discount

        def response(invoice)
          invoice[:discounts] ||= Basil.discount_ids(invoice)
        end
      end

      # https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations
      class InvoiceTaxes < Change
        applies_to VERSION, "invoice"
        removes :tax, :tax_percent, :total_tax_amounts

        def response(invoice)
          invoice[:total_taxes] ||=
            if invoice[:total_tax_amounts]
              invoice[:total_tax_amounts].map { |tax| Basil.tax(tax[:amount]) }
            else
              invoice[:tax] ? [Basil.tax(invoice[:tax])] : []
            end
        end
      end

      # https://docs.stripe.com/changelog/basil/2025-03-31/add-support-for-multiple-partial-payments-on-invoices
      class InvoicePayments < Change
        applies_to VERSION, "invoice"
        removes :charge, :payment_intent, :paid, :paid_out_of_band

        def response(invoice)
          invoice[:payments] ||= {
            object: "list",
            data: payment(invoice) ? [payment(invoice)] : [],
            has_more: false,
            url: "/v1/invoice_payments?invoice=#{invoice[:id]}"
          }
        end

        private

        def payment(invoice)
          charge = invoice[:charge]
          payment_intent = invoice[:payment_intent]
          payment_intent = payment_intent[:id] if payment_intent.respond_to?(:key?)
          return nil unless charge || payment_intent

          paid = invoice[:status] == "paid"
          {
            id: "inpay_#{invoice[:id]}",
            object: "invoice_payment",
            amount_paid: paid ? invoice[:amount_paid] : nil,
            amount_requested: invoice[:amount_due],
            currency: invoice[:currency],
            invoice: invoice[:id],
            is_default: true,
            livemode: false,
            payment: payment_intent ? { type: "payment_intent", payment_intent: payment_intent } : { type: "charge", charge: charge },
            status: paid ? "paid" : "open",
            status_transitions: { canceled_at: nil, paid_at: invoice.dig(:status_transitions, :paid_at) }
          }
        end
      end

      class LineItemParent < Change
        applies_to VERSION, "line_item"
        removes :type, :proration, :proration_details, :invoice_item, :subscription_item

        def response(line)
          details = {
            proration: line[:proration] || false,
            proration_details: line[:proration_details] || { credited_items: nil },
            subscription: line[:subscription]
          }
          line[:parent] ||=
            if line[:type] == "subscription"
              {
                type: "subscription_item_details",
                invoice_item_details: nil,
                subscription_item_details: details.merge(invoice_item: nil, subscription_item: line[:subscription_item])
              }
            else
              {
                type: "invoice_item_details",
                subscription_item_details: nil,
                invoice_item_details: details.merge(invoice_item: line[:invoice_item] || line[:id])
              }
            end
        end
      end

      # https://docs.stripe.com/changelog/basil/2025-03-31/invoice-pricing-configurations
      class LineItemPricing < Change
        applies_to VERSION, "line_item", "invoiceitem"
        removes :plan, :price, :unit_amount, :unit_amount_decimal, :unit_amount_excluding_tax

        def response(line)
          line[:pricing] ||= Basil.pricing(line[:price] || line[:plan])
        end
      end

      class LineItemTaxes < Change
        applies_to VERSION, "line_item"
        removes :tax_amounts, :tax_rates

        def response(line)
          line[:taxes] ||= (line[:tax_amounts] || []).map { |tax| Basil.tax(tax[:amount]) }
        end
      end

      class InvoiceItemParent < Change
        applies_to VERSION, "invoiceitem"
        removes :subscription, :subscription_item

        def response(item)
          item[:parent] ||= item[:subscription] && {
            type: "subscription_details",
            subscription_details: { subscription: item[:subscription], subscription_item: item[:subscription_item] }
          }
        end
      end
    end
  end
end
