module BrNfe
	module Service
		module Concerns
			module Rules
				module RecepcaoLoteRps
					extend ActiveSupport::Concern

					included do
					
						attr_accessor :lote_rps
						attr_accessor :numero_lote_rps
						attr_accessor :operacao

						validates :numero_lote_rps, presence: true
						validate  :validar_lote_rps
					
						def initialize(attributes = {})
							self.lote_rps = [] # Para poder utilizar o << para adicionar rps
							super
						end
						
						# Get lote_rps
						# Sobrescrito para sempre retornar um Array
						#
						# <b>Tipo de retorno: </b> _Array_
						#
						def lote_rps
							@lote_rps = [@lote_rps].flatten # Para retornar sempre um vetor
						end

						# Método que pode ser sobrescrito para cada orgão emissor que obriga
						# a inclusão de atributos fixos na tag LoteRps, além do ID.
						# Exemplo: <LoteRps id="lote_XXX" versao="1.00">
						# Nesse caso, o valor do método deve ser: {versao: "1.00"}
						#
						# <b>Tipo de retorno: </b> _Hash_
						#
						def lote_rps_fixed_attributes
							{}
						end
						
						private

							def validar_lote_rps
								if lote_rps.empty?
									errors.add(:base, "Deve conter ao menos 1 RPS")
								else
									lote_rps.each_with_index do |rps, i|
										rps.validar_recepcao_rps = true
										if rps.invalid?
											rps.errors.full_messages.map{|msg| errors.add(:base, "RPS #{i+1}: #{msg}") } 
										end
									end
								end
							end
						end
					end
			end
		end
	end
end