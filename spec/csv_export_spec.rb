require 'spec_helper'

describe CsvExport do
  subject { CsvExport.new('Australia', 'Senate') }
  let(:user) { User.create(name: 'Bob Test', uid: '42', provider: 'twitter') }

  before do
    stub_request(:get, Everypolitician.countries_json)
      .to_return(status: 200, body: File.read('spec/fixtures/countries.json'))
    {
      'politician1' => 'male',
      'politician2' => 'male',
      'politician3' => 'female'
    }.each do |politician_id, choice|
      CountryUUID.create(
        country_slug: 'Australia',
        legislature_slug: 'Senate',
        uuid: politician_id
      )
      CountryUUID.create(
        country_slug: 'Australia',
        legislature_slug: 'Assembly',
        uuid: politician_id
      )
      Vote.create(
        user_id: user.id,
        person_uuid: politician_id,
        choice: choice
      )
    end
  end

  it 'returns the correct CSV' do
    expected = [
      { 'uuid' => 'politician1', 'female' => '0', 'male' => '1', 'other' => '0', 'skip' => '0', 'total' => '1' },
      { 'uuid' => 'politician2', 'female' => '0', 'male' => '1', 'other' => '0', 'skip' => '0', 'total' => '1' },
      { 'uuid' => 'politician3', 'female' => '1', 'male' => '0', 'other' => '0', 'skip' => '0', 'total' => '1' }
    ]
    actual = CSV.parse(subject.to_csv, headers: true)
    assert_equal expected, actual.map(&:to_hash)
  end
end
