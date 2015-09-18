require 'test_helper'

describe BrNfe::Servico::Betha::V1::Gateway do
	subject             { FactoryGirl.build(:br_nfe_servico_betha_gateway, emitente: emitente) }
	let(:rps)           { FactoryGirl.build(:br_nfe_rps, :completo) }
	let(:emitente)      { FactoryGirl.build(:emitente) }
	let(:intermediario) { FactoryGirl.build(:intermediario) }

	describe "inheritance class" do
		it { subject.class.superclass.must_equal BrNfe::Servico::Betha::Base }
	end

	describe "#namespaces" do
		it "deve ter um valor" do
			subject.namespaces.must_equal({"xmlns:ns1" => "http://www.betha.com.br/e-nota-contribuinte-ws"})
		end
	end

	describe "#namespace_identifier" do
		it "deve ter o valor ns1" do
			subject.namespace_identifier.must_equal :ns1
		end
	end

	describe "#version" do
		it { subject.version.must_equal :v1 }
	end

	describe "#content_xml" do
		it "canonicaliza o xml_builder e remove as tags <Temp>" do
			subject.expects(:xml_builder).returns('<?xml version="1.0" encoding="UTF-8"?>'+"\n<Temp>\n\t <AlgumaTag>ValorXXX</AlgumaTag>\n</Temp>")
			subject.content_xml.must_equal "<AlgumaTag>ValorXXX</AlgumaTag>"
		end
	end

	describe "#tag_dados_servico" do
		it "deve vir com a estrutura adecuada com todos os valores preenchidos" do
			xml = Nokogiri::XML::Builder.new do |xml|
				subject.send(:tag_dados_servico, xml, rps)
			end.doc

			xml.xpath('Servico/ItemListaServico').first.text.must_equal          rps.item_lista_servico
			xml.xpath('Servico/CodigoCnae').first.text.must_equal                rps.codigo_cnae
			xml.xpath('Servico/CodigoTributacaoMunicipio').first.text.must_equal rps.codigo_tributacao_municipio
			xml.xpath('Servico/Discriminacao').first.text.must_equal             rps.discriminacao
			xml.xpath('Servico/CodigoMunicipio').first.text.must_equal           rps.codigo_municipio
			
			xml.xpath('Servico/Valores/ValorServicos').first.text.must_equal   rps.valor_servicos.to_f.round(2).to_s
			xml.xpath('Servico/Valores/IssRetido').first.text.must_equal       '2'
			xml.xpath('Servico/Valores/BaseCalculo').first.text.must_equal     rps.base_calculo.to_f.round(2).to_s
			xml.xpath('Servico/Valores/ValorDeducoes').first.text.must_equal   rps.valor_deducoes.to_f.round(2).to_s
			xml.xpath('Servico/Valores/ValorPis').first.text.must_equal        rps.valor_pis.to_f.round(2).to_s
			xml.xpath('Servico/Valores/ValorCofins').first.text.must_equal     rps.valor_cofins.to_f.round(2).to_s
			xml.xpath('Servico/Valores/ValorInss').first.text.must_equal       rps.valor_inss.to_f.round(2).to_s
			xml.xpath('Servico/Valores/ValorIr').first.text.must_equal         rps.valor_ir.to_f.round(2).to_s
			xml.xpath('Servico/Valores/ValorCsll').first.text.must_equal       rps.valor_csll.to_f.round(2).to_s
			xml.xpath('Servico/Valores/ValorIss').first.text.must_equal        rps.valor_iss.to_f.round(2).to_s
			xml.xpath('Servico/Valores/OutrasRetencoes').first.text.must_equal rps.outras_retencoes.to_f.round(2).to_s
			xml.xpath('Servico/Valores/Aliquota').first.text.must_equal        rps.aliquota.to_f.round(2).to_s
		end

		it "sem os valores não obrigatórios" do
			rps.assign_attributes({valor_deducoes: '', valor_pis: '', valor_cofins: '',
				valor_inss: '', valor_ir: '', valor_csll: '', valor_iss: '', outras_retencoes: '',
				aliquota: '', codigo_cnae: '', codigo_tributacao_municipio: ''
			})

			xml = Nokogiri::XML::Builder.new do |xml|
				subject.send(:tag_dados_servico, xml, rps)
			end.doc


			xml.xpath('Servico/CodigoCnae').first.must_be_nil
			xml.xpath('Servico/CodigoTributacaoMunicipio').first.must_be_nil
			xml.xpath('Servico/Valores/ValorDeducoes').first.must_be_nil
			xml.xpath('Servico/Valores/ValorPis').first.must_be_nil
			xml.xpath('Servico/Valores/ValorCofins').first.must_be_nil
			xml.xpath('Servico/Valores/ValorInss').first.must_be_nil
			xml.xpath('Servico/Valores/ValorIr').first.must_be_nil
			xml.xpath('Servico/Valores/ValorCsll').first.must_be_nil
			xml.xpath('Servico/Valores/ValorIss').first.must_be_nil
			xml.xpath('Servico/Valores/OutrasRetencoes').first.must_be_nil
			xml.xpath('Servico/Valores/Aliquota').first.must_be_nil			
		end
	end

	context "#tag_prestador" do
		it "estrutura com todos os atributos" do
			xml = Nokogiri::XML::Builder.new do |xml|
				subject.send(:tag_prestador, xml)
			end.doc

			xml.xpath('Prestador/Cnpj').first.text.must_equal emitente.cnpj
			xml.xpath('Prestador/InscricaoMunicipal').first.text.must_equal emitente.inscricao_municipal
		end
		it "estrutura sem os atributos não obrigatorios" do
			emitente.inscricao_municipal = ''
			
			xml = Nokogiri::XML::Builder.new do |xml|
				subject.send(:tag_prestador, xml)
			end.doc

			xml.xpath('Prestador/InscricaoMunicipal').first.must_be_nil
		end
	end

	context "#tag_intermediario_servico" do
		it "estrutura com todos os atributos" do
			xml = Nokogiri::XML::Builder.new do |xml|
				subject.send(:tag_intermediario_servico, xml, intermediario)
			end.doc

			xml.xpath('IntermediarioServico/RazaoSocial').first.text.must_equal        intermediario.razao_social
			xml.xpath('IntermediarioServico/CpfCnpj/Cnpj').first.text.must_equal       BrNfe::Helper::CpfCnpj.new(intermediario.cpf_cnpj).sem_formatacao
			xml.xpath('IntermediarioServico/InscricaoMunicipal').first.text.must_equal intermediario.inscricao_municipal
		end
		it "estrutura sem os atributos não obrigatorios" do
			intermediario.assign_attributes({cpf_cnpj: '132.456.789-01', inscricao_municipal: ''})
			xml = Nokogiri::XML::Builder.new do |xml|
				subject.send(:tag_intermediario_servico, xml, intermediario)
			end.doc

			xml.xpath('IntermediarioServico/CpfCnpj/Cpf').first.text.must_equal  BrNfe::Helper::CpfCnpj.new(intermediario.cpf_cnpj).sem_formatacao
			xml.xpath('IntermediarioServico/InscricaoMunicipal').first.must_be_nil
		end
		it "se não tiver intermediario não monta o xml" do
			xml = Nokogiri::XML::Builder.new do |xml|
				subject.send(:tag_intermediario_servico, xml, nil)
			end.doc

			xml.root.to_s.must_equal ''
		end
	end

	describe "#tag_condicao_pagamento" do
		it "estrutura a prazo" do
			xml = Nokogiri::XML::Builder.new do |xml|
				subject.send(:tag_condicao_pagamento, xml, rps)
			end.doc

			xml.xpath('CondicaoPagamento/Condicao').first.text.must_equal                rps.condicao_pagamento.condicao
			xml.xpath('CondicaoPagamento/QtdParcela').first.text.must_equal              '2'
			
			xml.xpath('CondicaoPagamento/Parcelas/Parcela').first.text.must_equal        '1'
			xml.xpath('CondicaoPagamento/Parcelas/DataVencimento').first.text.must_equal '2015-10-15'
			xml.xpath('CondicaoPagamento/Parcelas/Valor').first.text.must_equal          '10.0'

			xml.xpath('CondicaoPagamento/Parcelas/Parcela').last.text.must_equal        '2'
			xml.xpath('CondicaoPagamento/Parcelas/DataVencimento').last.text.must_equal '2015-11-15'
			xml.xpath('CondicaoPagamento/Parcelas/Valor').last.text.must_equal          '20.0'
		end

		it "estrutura a vista" do
			rps.condicao_pagamento.assign_attributes(condicao: 'A_VISTA', parcelas: [])
			xml = Nokogiri::XML::Builder.new do |xml|
				subject.send(:tag_condicao_pagamento, xml, rps)
			end.doc

			xml.xpath('CondicaoPagamento/Condicao').first.text.must_equal   'A_VISTA'
			xml.xpath('CondicaoPagamento/QtdParcela').first.must_be_nil
			
			xml.xpath('CondicaoPagamento/Parcelas').first.must_be_nil
		end

		it "quando não tem condicao_pagamento" do
			rps.condicao_pagamento = nil
			xml = Nokogiri::XML::Builder.new do |xml|
				subject.send(:tag_condicao_pagamento, xml, rps)
			end.doc
			xml.root.to_s.must_equal ''
		end
	end

end