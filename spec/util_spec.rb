require 'spec_helper'

describe StripeMock::Util do

  describe 'rmerge' do
    it "recursively merges a simple hash" do
      dest = { x: { y: 50 }, a: 5, b: 3 }
      source = { x: { y: 999 }, a: 77 }
      result = StripeMock::Util.rmerge(dest, source)

      expect(result).to eq({ x: { y: 999 }, a: 77, b: 3 })
    end

    it "recursively merges a nested hash" do
      dest = { x: { y: 50, z: { m: 44, n: 4 } } }
      source = { x: { y: 999, z: { n: 55 } } }
      result = StripeMock::Util.rmerge(dest, source)

      expect(result).to eq({ x: { y: 999, z: { m: 44, n: 55 } } })
    end

    it "merges array elements (that are hashes)" do
      dest = { x: [ {a: 1}, {b: 2}, {c: 3} ] }
      source = { x: [ {a: 0}, {a: 0} ] }
      result = StripeMock::Util.rmerge(dest, source)

      expect(result).to eq({ x: [ {a: 0}, {a: 0, b: 2}, {c: 3} ] })
    end

    context "array elements (that are simple values)" do
      it "merges arrays" do
        dest = { x: [ 1, 2 ] }
        source = { x: [ 3, 4 ] }
        result = StripeMock::Util.rmerge(dest, source)

        expect(result).to eq({ x: [ 1, 3, 2, 4 ] })
      end

      it "ignores empty arrays" do
        dest = { x: [] }
        source = { x: [ 3, 4 ] }
        result = StripeMock::Util.rmerge(dest, source)

        expect(result).to eq({ x: [ 3, 4 ] })
      end

      it "removes nil values" do
        dest = { x: [ 1, 2, nil ] }
        source = { x: [ nil, 3, 4 ] }
        result = StripeMock::Util.rmerge(dest, source)

        expect(result).to eq({ x: [ 1, 2, 3, 4 ] })
      end

      it "respects duplicate values" do
        dest = { x: [ 1, 2, 3 ] }
        source = { x: [ 3, 4 ] }
        result = StripeMock::Util.rmerge(dest, source)

        expect(result).to eq({ x: [ 1, 3, 2, 4, 3 ] })
      end
    end

    it "does not truncate the array when merging" do
      dest = { x: [ {a: 1}, {b: 2} ] }
      source = { x: [ nil, nil, {c: 3} ] }
      result = StripeMock::Util.rmerge(dest, source)

      expect(result).to eq({ x: [ {a: 1}, {b: 2}, {c: 3} ] })
    end

    it "treats an array nil element as a skip op" do
      dest = { x: [ {a: 1}, {b: 2}, {c: 3} ] }
      source = { x: [ nil, nil, {c: 0} ] }
      result = StripeMock::Util.rmerge(dest, source)

      expect(result).to eq({ x: [ {a: 1}, {b: 2}, {c: 0} ] })
    end

    it "treats nil as a replacement otherwise" do
      dest = { x: 99 }
      source = { x: nil }
      result = StripeMock::Util.rmerge(dest, source)

      expect(result).to eq({ x: nil })
    end
  end

  describe 'card_merge' do
    it 'merges last4 into number' do
      new_param = {  last4: '9999' }
      old_param = { number: '4242424242424242' }
      result = StripeMock::Util.card_merge(old_param, new_param)
      expect(result[:last4]).to eq('9999')
      expect(result[:number]).to eq('4242424242429999')
    end

    it 'overwrites old last4 if new number given' do
      new_param = { number: '9999999999999999' }
      old_param = { number: '4242424242424242', last4: '4242' }
      result = StripeMock::Util.card_merge(old_param, new_param)
      expect(result[:last4]).to eq('9999')
      expect(result[:number]).to eq('9999999999999999')
    end

    it 'uses last4 in preference to number if both given' do
      new_param = { number: '9999999999999999', last4: '1111' }
      old_param = { number: '4242424242424242', last4: '4242' }
      result = StripeMock::Util.card_merge(old_param, new_param)
      expect(result[:last4]).to eq('1111')
      expect(result[:number]).to eq('9999999999991111')
    end

    it 'simple merge if old and new cards are missing number' do
      new_param = { last4: '1111' }
      old_param = { last4: '4242' }
      result = StripeMock::Util.card_merge(old_param, new_param)
      expect(result[:last4]).to eq('1111')
    end
  end

  describe 'expand' do
    context 'when the object is expandable' do
      it 'returns a matching object from the collection' do
        bl_txn_id = "bl_1234"
        obj = { latest_charge: { balance_transaction: bl_txn_id } }
        collection = { bl_txn_id => { 'status' => 'active' } }

        result = described_class.expand(collection, obj, 'latest_charge.balance_transaction')

        expect(result['status']).to eq('active')
      end
    end
    context 'when the object is not expandable' do
      it 'returns the existing object' do
        bl_txn_id = "bl_1234"
        obj = { latest_charge: { balance_transaction: { id: bl_txn_id } } }
        collection = { bl_txn_id => { 'status' => 'active' } }

        result = described_class.expand(collection, obj, 'latest_charge.balance_transaction')

        expect(result).to eq(id: bl_txn_id)
      end
    end
  end

  describe 'expandable' do
    context 'when invalid input' do
      it 'must be given a hash' do
        result = described_class.expandable('a', 'latest_charge')

        expect(result).to be false
      end

      it 'the expand param must be a key in the hash' do
        result = described_class.expandable({}, 'latest_charge')

        expect(result).to be false
      end
    end

    it 'the value of the expand param can be a string' do
      result = described_class.expandable({ latest_charge: 'ch_1234' }, 'latest_charge')

      expect(result).to be true
    end

    context 'when nested expand params' do
      it 'the nested attribute must exist in the hash' do
        obj = { latest_charge: { balance_transaction: { id: "bl_1234" } } }

        result = described_class.expandable(obj, 'latest_charge.balance_transaction')

        expect(result).to be false
      end

      it 'the value of the nested attribute must be a hash' do
        obj = { latest_charge: { balance_transaction: "bl_1234" } }

        result = described_class.expandable(obj, 'latest_charge.balance_transaction')

        expect(result).to be true
      end
    end

    context "when nested nested params" do
      it 'the nested attributes must exist in the hash' do
        obj = { latest_charge: { balance_transaction: { fee: "fee_1234" } } }

        result = described_class.expandable(obj, 'latest_charge.balance_transaction.fee')

        expect(result).to be true
      end
    end
  end
end
