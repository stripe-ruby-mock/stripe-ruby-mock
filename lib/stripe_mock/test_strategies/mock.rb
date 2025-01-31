module StripeMock
  module TestStrategies
    class Mock < Base

      def delete_product(product_id)
        if StripeMock.state == 'remote'
          StripeMock.client.destroy_resource('products', product_id)
        elsif StripeMock.state == 'local'
          StripeMock.instance.products.delete(product_id)
        end
      end

      def delete_plan(plan_id)
        if StripeMock.state == 'remote'
          StripeMock.client.destroy_resource('plans', plan_id)
        elsif StripeMock.state == 'local'
          StripeMock.instance.plans.delete(plan_id)
        end
      end

      def create_sku(params={})
        Stripe::SKU.create create_sku_params(params)
      end

      def delete_sku(sku_id)
        if StripeMock.state == 'remote'
          StripeMock.client.destroy_resource('skus', sku_id)
        elsif StripeMock.state == 'local'
          StripeMock.instance.skus.delete(sku_id)
        end
      end

      def upsert_stripe_object(object, attributes = {})
        if StripeMock.state == 'remote'
          StripeMock.client.upsert_stripe_object(object, attributes)
        elsif StripeMock.state == 'local'
          StripeMock.instance.upsert_stripe_object(object, attributes)
        end
      end

      def automatic_confirm_payment_intent(client_secret)
        pi_id = StripeMock.instance.payment_intents.find { |_k, v| v[:client_secret] == client_secret }[0]

        if StripeMock.instance.payment_intents[pi_id][:status] == 'requires_confirmation' || StripeMock.instance.payment_intents[pi_id][:status] == 'requires_action'
          is_paid = StripeMock.instance.payment_methods[StripeMock.instance.payment_intents[pi_id][:payment_method]][:card][:last4] != '3178'

          charge = Stripe::Charge.create({
            customer: StripeMock.instance.payment_intents[pi_id][:customer],
            amount: StripeMock.instance.payment_intents[pi_id][:amount],
            payment_method: StripeMock.instance.payment_intents[pi_id][:payment_method],
            payment_intent: StripeMock.instance.payment_intents[pi_id][:id],
            currency: StripeMock.instance.payment_intents[pi_id][:currency],
            paid: is_paid,
            failure_code: is_paid ? nil : "card_declined",
            failure_message: is_paid ? nil : "Your card has insufficient funds.",
            status: is_paid ? 'succeeded' : 'failed'
          })

          if is_paid && !StripeMock.instance.payment_intents[pi_id][:invoice].nil?
            StripeMock.instance.invoices[StripeMock.instance.payment_intents[pi_id][:invoice]][:paid] = is_paid
          end

          StripeMock.instance.payment_intents[pi_id][:charges][:total_count] += 1
          StripeMock.instance.payment_intents[pi_id][:charges][:data] << charge
          StripeMock.instance.payment_intents[pi_id][:status] = is_paid ? 'succeeded' : 'requires_payment_method'
        end

        StripeMock.instance.payment_intents[pi_id]
      end
    end
  end
end
