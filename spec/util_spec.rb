require 'spec_helper'

describe StripeMock::Util do

  it "recursively merges a simple hash" do
    hash_one = { x: { y: 50 }, a: 5, b: 3 }
    hash_two = { x: { y: 999 }, a: 77 }
    result = StripeMock::Util.rmerge(hash_one, hash_two)

    expect(result).to eq({ x: { y: 999 }, a: 77, b: 3 })
  end

  it "recursively merges a nested hash" do
    hash_one = { x: { y: 50, z: { m: 44, n: 4 } } }
    hash_two = { x: { y: 999, z: { n: 55 } } }
    result = StripeMock::Util.rmerge(hash_one, hash_two)

    expect(result).to eq({ x: { y: 999, z: { m: 44, n: 55 } } })
  end

  it "merges array elements" do
    hash_one = { x: [ {a: 1}, {b: 2}, {c: 3} ] }
    hash_two = { x: [ {a: 0}, {a: 0} ] }
    result = StripeMock::Util.rmerge(hash_one, hash_two)

    expect(result).to eq({ x: [ {a: 0}, {a: 0, b: 2}, {c: 3} ] })
  end

  it "treats an array nil element as a skip op" do
    hash_one = { x: [ {a: 1}, {b: 2}, {c: 3} ] }
    hash_two = { x: [ nil, nil, {c: 0} ] }
    result = StripeMock::Util.rmerge(hash_one, hash_two)

    expect(result).to eq({ x: [ {a: 1}, {b: 2}, {c: 0} ] })
  end

  it "treats nil as a replacement otherwise" do
    hash_one = { x: 99 }
    hash_two = { x: nil }
    result = StripeMock::Util.rmerge(hash_one, hash_two)

    expect(result).to eq({ x: nil })
  end

end
