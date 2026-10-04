component extends="coldbox.system.EventHandler" secured="true" {

	property name="categoriaService" inject="CategoriaService";

	this.allowedMethods = {
		index : "GET", adicionar : "GET", criar : "POST", editar : "GET", confirmarInativacao : "GET", salvar : "POST", inativar : "POST", reativar : "PUT"
	};

	public void function index( event, rc, prc ) {
		prc.titulo = "Categorias de fornecedores";
		prc.categorias = variables.categoriaService.listarParaGestao();
		prc.mensagem = flash.get( "categoriasMensagem", "" );
		event.setView( "categorias/index" );
	}

	public void function adicionar( event, rc, prc ) {
		prc.categoria = { txCategoria : "" };
		prepararFormulario( event, prc, true );
	}

	public void function criar( event, rc, prc ) {
		prc.categoria = { txCategoria : "" };
		local.formulario = popularValidarDTO( "criar" );
		variables.categoriaService.criarCategoria( local.formulario.getTxCategoria() );
		flash.put( "categoriasMensagem", "Categoria criada com sucesso." );
		relocate( uri = "/categorias", statusCode = 303 );
	}

	public void function editar( event, rc, prc ) {
		local.identificador = populateModel( model = "CategoriaDTO", include = "cdCategoria" );
		prc.categoria = variables.categoriaService.obterCategoria( local.identificador.getCdCategoria() );
		prepararFormulario( event, prc );
	}

	public void function confirmarInativacao( event, rc, prc ) {
		local.identificador = populateModel( model = "CategoriaDTO", include = "cdCategoria" );
		prc.categoria = variables.categoriaService.obterCategoria( local.identificador.getCdCategoria() );
		prc.titulo = "Inativar categoria";
		event.setView( "categorias/inativar" );
	}

	public void function salvar( event, rc, prc ) {
		local.categoriaDTO = populateModel( model = "CategoriaDTO", include = "cdCategoria,txCategoria" );
		prc.categoria = variables.categoriaService.obterCategoria( local.categoriaDTO.getCdCategoria() );
		validarCategoriaDTO( local.categoriaDTO, "editar" );
		variables.categoriaService.editarCategoria( local.categoriaDTO.getCdCategoria(), local.categoriaDTO.getTxCategoria() );
		flash.put( "categoriasMensagem", "Categoria atualizada com sucesso." );
		relocate( uri = "/categorias", statusCode = 303 );
	}

	public void function inativar( event, rc, prc ) {
		local.identificador = populateModel( model = "CategoriaDTO", include = "cdCategoria" );
		variables.categoriaService.inativarCategoria( local.identificador.getCdCategoria() );
		flash.put( "categoriasMensagem", "Categoria inativada com sucesso." );
		relocate( uri = "/categorias", statusCode = 303 );
	}

	public void function onError( event, rc, prc, faultAction, exception, eventArguments ) {
		arguments.prc.erroNotificacao = arguments.exception;
		if ( arguments.faultAction EQ "reativar" ) {
			local.status = 500;
			local.mensagem = "Não foi possível reativar a categoria. Tente novamente em instantes.";
			switch ( arguments.exception.type ) {
				case "CategoriaInvalida": local.status = 422; break;
				case "CategoriaNaoEncontrada": local.status = 404; break;
				case "InvalidHTTPMethod":
					local.status = 405;
					arguments.event.setHTTPHeader( name = "Allow", value = "PUT" );
					local.mensagem = "Use PUT para reativar a categoria.";
					break;
			}
			if ( local.status EQ 422 OR local.status EQ 404 ) local.mensagem = arguments.exception.message;
			if ( local.status EQ 500 ) log.error( "Falha ao reativar categoria (#arguments.exception.type#)." );
			arguments.event.renderData( type = "json", statusCode = local.status, data = { erro : local.mensagem } );
			return;
		}
		if ( arguments.exception.type EQ "InvalidHTTPMethod" ) {
			throw( object = arguments.exception );
		}
		if (
			( arguments.faultAction EQ "salvar" OR arguments.faultAction EQ "criar" ) AND
			arguments.exception.type EQ "CategoriaInvalida" AND
			structKeyExists( arguments.prc, "categoria" )
		) {
			arguments.prc.categoria.txCategoria = isSimpleValue( arguments.rc.txCategoria ?: "" ) ? ( arguments.rc.txCategoria ?: "" ) : "";
			arguments.prc.erroNome = arguments.exception.message;
			arguments.event.setHTTPHeader( statusCode = 422 );
			prepararFormulario( arguments.event, arguments.prc, arguments.faultAction EQ "criar" );
			return;
		}
		exibirErro( arguments.event, arguments.prc, arguments.exception );
	}

	public void function reativar( event, rc, prc ) {
		local.categoria = variables.categoriaService.reativarCategoria( arguments.rc.cdCategoria ?: "" );
		arguments.event.renderData( type = "json", statusCode = 200, data = local.categoria );
	}

	private any function popularValidarDTO( required string perfil ) {
		local.dto = getInstance( "CategoriaDTO" );
		populateModel( model = local.dto, include = local.dto.constraintProfiles[ arguments.perfil ] );
		validarCategoriaDTO( local.dto, arguments.perfil );
		return local.dto;
	}

	private void function validarCategoriaDTO( required any dto, required string perfil ) {
		local.resultado = validate( target = arguments.dto, profiles = arguments.perfil );
		if ( local.resultado.hasErrors() ) {
			throw( type = "CategoriaInvalida", message = local.resultado.getAllErrors()[ 1 ] );
		}
	}

	private void function prepararFormulario( required any event, required struct prc, boolean nova = false ) {
		arguments.prc.titulo = arguments.nova ? "Nova categoria" : "Editar categoria";
		param arguments.prc.erroNome = "";
		arguments.event.setView( arguments.nova ? "categorias/adicionar" : "categorias/editar" );
	}


	private void function exibirErro( required any event, required struct prc, required any erro ) {
		local.status = 500;
		arguments.prc.titulo = "Não foi possível concluir";
		arguments.prc.erro = "Não foi possível acessar as categorias. Tente novamente em instantes.";
		if ( arguments.erro.type EQ "CategoriaNaoEncontrada" ) {
			local.status = 404;
			arguments.prc.erro = arguments.erro.message;
		} else if ( arguments.erro.type EQ "CategoriaInvalida" ) {
			local.status = 422;
			arguments.prc.erro = arguments.erro.message;
		} else {
			log.error( "Falha no gerenciamento de categorias (#arguments.erro.type#)." );
		}
		arguments.event.setHTTPHeader( statusCode = local.status );
		arguments.event.setView( "categorias/erro" );
	}

}
