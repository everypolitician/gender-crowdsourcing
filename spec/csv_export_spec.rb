require 'spec_helper'

describe CsvExport do
  subject { CsvExport.new('pol1' => { 'female' => 2, 'male' => 1 }) }

  it 'generates a CSV from the input hash' do
    expected = "uuid,female,male,other,skip,total\npol1,2,1,,,3\n"
    assert_equal expected, subject.to_csv
  end
end
