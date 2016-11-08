require 'test_helper'

describe BrNfe::Product::Cobranca::Duplicata do
	subject { FactoryGirl.build(:product_cobranca_duplicata) }

	describe 'Validations' do
		it { must validate_presence_of(:total) }
		it { must validate_numericality_of(:total).is_greater_than_or_equal_to(0.0) }
		it { must validate_length_of(:numero_duplicata).is_at_most(60) }
	end
	

end