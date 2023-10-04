@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS Libros'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Metadata.allowExtensions: true

define view entity zc_libros_4236
  as select from    zlibros_4236      as Libros
    inner join      zcatego_4236      as Categoria on Libros.bi_categ = Categoria.bi_categ
    left outer join zc_clnts_lib_4236 as Ventas    on Libros.id_libro = Ventas.IdLibro
  association [0..*] to ZC_clientes_4236 as _Clientes on $projection.IdLibro = _Clientes.IdLibro
{
  key Libros.id_libro       as IdLibro,
      Libros.titulo         as Titulo,
      Libros.bi_categ       as Categoria,
      Libros.autor          as Autor,
      Libros.editorial      as Editorial,
      Libros.idioma         as Idioma,
      Libros.paginas        as Paginas,
      @Semantics.amount.currencyCode: 'Moneda'
      Libros.precio         as Precio,
      case
        when Ventas.Ventas < 1 then 0
        when Ventas.Ventas = 1 then 1
        when Ventas.Ventas = 2 then 2
        else 3
        end                 as Ventas,
      case Ventas.Ventas
      when 0 then ' '
      else ''
      end                   as Text,
      Libros.moneda         as Moneda,
      Libros.formato        as Formato,
      Categoria.descripcion as Descripcion,
      Libros.url            as Imagen,
      _Clientes
}
