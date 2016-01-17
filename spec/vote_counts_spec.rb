require 'spec_helper'

describe VoteCounts do
  subject { VoteCounts.new('AU', 'Senate', id_map) }
  let(:user) { User.create(name: 'Bob Test', uid: '42', provider: 'twitter') }
  let(:legislative_period) { LegislativePeriod.create(country_code: 'AU', legislature_slug: 'Senate', legislative_period_id: 2, start_date: Date.new(2010)) }
  let(:id_map) do
    {
      'politician1' => 'pol1',
      'politician2' => 'pol2',
      'politician3' => 'pol3'
    }
  end

  before do
    {
      'politician1' => 'male',
      'politician2' => 'male',
      'politician3' => 'female'
    }.each do |politician_id, choice|
      Response.create(
        user_id: user.id,
        politician_id: politician_id,
        legislative_period_id: legislative_period.id,
        choice: choice
      )
    end
  end

  it 'returns the correct CSV' do
    expected = { 'pol1' => { 'male' => 1 }, 'pol2' => { 'male' => 1 }, 'pol3' => { 'female' => 1 } }
    assert_equal expected, subject.to_hash
  end
end
