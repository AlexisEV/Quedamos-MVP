-- catalogo manual de lugares de arequipa generado desde supabase/catalogo_lugares.csv (rf11, rb09)
-- celdas vacias se guardan como null, que la app muestra como desconocido
-- precio_nota del csv no se carga: las notas son referencia interna del equipo
-- idempotente: no inserta un lugar que ya exista con el mismo nombre y zona

begin;

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Zig Zag Restaurante', 'restaurantes'::public.lugar_categoria, 'centro_historico'::public.lugar_zona, 'Calle Zela 210', '-16.395262'::numeric, '-71.535516'::numeric, 'Lun–Dom: 12:00–22:00', '74.00'::numeric, 'Página oficial (dirección y horario): https://zigzagrestaurant.com/reservas/ | Precio: cálculo por persona documentado en Menus/ESTIMADOS_PRECIOS.md y Menus/ZigZag/precios_extraidos.json; fuentes: ZigZag-cartacomidas.pdf; decisiones del usuario del 2026-10-24. | Coordenadas WGS84 verificadas (2026-10-24): https://www.waze.com/live-map/directions/zig-zag-zela-210-arequipa?to=place.w.189072996.1890467816.4494474.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Zig Zag Restaurante' and l.zona = 'centro_historico'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'La Despensa', 'cafes_y_postres'::public.lugar_categoria, 'centro_historico'::public.lugar_zona, 'Calle Santa Catalina 302, Arequipa', '-16.395571'::numeric, '-71.536244'::numeric, 'Lun–Sáb: 09:00–22:00; Dom: 09:00–21:00', '19.00'::numeric, 'Web oficial, carta y dirección: https://ladespensa.com.pe/menu/ ; contacto oficial: https://ladespensa.com.pe/contacto/ ; horario y coordenadas WGS84 (GeoCoordinates de ficha La Despensa, mismo teléfono 054 222104): https://www.waze.com/es/live-map/directions/la-despensa-arequipa?to=place.w.189072996.1890467816.13873708 ; horario corroborado por dirección Santa Catalina 302: https://wanderlog.com/place/details/2921596/la-despensa', '2026-10-25'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'La Despensa' and l.zona = 'centro_historico'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Museo del Pisco - Arequipa', 'bares'::public.lugar_categoria, 'centro_historico'::public.lugar_zona, 'Calle Moral 229', '-16.397060'::numeric, '-71.536759'::numeric, 'Lun–Sáb: 12:00–00:00; Dom: 12:00–23:00', '60.00'::numeric, 'Mesa 24/7 (bar, dirección y precio promedio): https://www.mesa247.pe/arequipa/restaurante/museo-del-pisco-arequipa | Precio de referencia verificado (2026-10-24): https://www.mesa247.pe/arequipa/restaurante/museo-del-pisco-arequipa. | Coordenadas WGS84 verificadas (2026-10-24): https://www.mesa247.pe/arequipa/restaurante/museo-del-pisco-arequipa. Horario/estado elegido (2026-10-24): https://restaurantguru.com/Museo-del-Pisco-Arequipa.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Museo del Pisco - Arequipa' and l.zona = 'centro_historico'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Chelawasi Public House', 'bares'::public.lugar_categoria, 'centro_historico'::public.lugar_zona, 'Campo Redondo 102', '-16.393560'::numeric, '-71.533460'::numeric, 'Lun–Jue: 12:30–23:00; Vie–Sáb: 11:30–01:30; Dom: 14:00–22:00', '57.00'::numeric, 'Directorio FeelingPeru (bar, dirección y horario): https://feelingperu.com/chelawasi-public-house-arequipa/ ; corroboración de ubicación y actividad: https://birrapedia.com/chelawasi-public-house/e-59d355551603dad04a03a2c7 | Precio: cálculo por persona documentado en Menus/ESTIMADOS_PRECIOS.md y Menus/Chelawasi/precios_extraidos.json; fuentes: ES_COMIDA.pdf, DRAFT BEERS.pdf; decisiones del usuario del 2026-10-24. | Coordenadas WGS84 verificadas (2026-10-24): https://mapcarta.com/N4187752193.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Chelawasi Public House' and l.zona = 'centro_historico'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Monasterio de Santa Catalina', 'entretenimiento_y_cultura'::public.lugar_categoria, 'centro_historico'::public.lugar_zona, 'Calle Santa Catalina 301', '-16.396110'::numeric, '-71.536577'::numeric, 'Lun, Jue–Dom: 09:00–17:00; Mar–Mié: 09:00–20:00', '50.00'::numeric, 'Página oficial (dirección, horario y tarifas): https://santacatalina.org.pe/horarios-y-precios/ ; guiado opcional: https://storesantacatalina.org.pe/ | Precio de referencia verificado (2026-10-24): https://santacatalina.org.pe/horarios-y-precios/. | Coordenadas WGS84 verificadas (2026-10-24): https://www.waze.com/es-419/live-map/directions/pe/arequipa/arequipa/monasterio-de-santa-catalina-de-siena?navigate=yes&to=place.ChIJvQaEStk3B5ERkAXTm611nwY.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Monasterio de Santa Catalina' and l.zona = 'centro_historico'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'La Nueva Palomino', 'restaurantes'::public.lugar_categoria, 'yanahuara'::public.lugar_zona, 'Pasaje Leoncio Prado 122', '-16.387075'::numeric, '-71.539547'::numeric, 'Lun–Sáb: 12:00–16:30; Dom: 07:30–10:30 / 12:00–16:30', '68.00'::numeric, 'Directorio Limeo (dirección, actividad y horario elegido entre fuentes discrepantes; sin fecha explícita de actualización): https://limeo.pe/en/restaurante/la-nueva-palomino-arequipa | Precio: cálculo por persona documentado en Menus/ESTIMADOS_PRECIOS.md y Menus/LaNuevaPalomino/precios_extraidos.json; fuentes: LaNuevaPalomino.pdf; decisiones del usuario del 2026-10-24. | Coordenadas WGS84 verificadas (2026-10-24): https://www.waze.com/live-map/directions/pe/arequipa/yanahuara/la-nueva-palomino?to=place.ChIJzddQfUZKQpERT1nVo0kCtj0.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'La Nueva Palomino' and l.zona = 'yanahuara'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Sol de Mayo', 'restaurantes'::public.lugar_categoria, 'yanahuara'::public.lugar_zona, 'Calle Jerusalén 207', '-16.389933'::numeric, '-71.544417'::numeric, 'Lun–Dom: 12:00–18:00', '57.00'::numeric, 'Directorio Restaurant Guru (dirección y horario): https://es.restaurantguru.com/Sol-de-Mayo-Arequipa | Precio: cálculo por persona documentado en Menus/ESTIMADOS_PRECIOS.md y Menus/SolDeMayo/precios_extraidos.json; fuentes: 9.webp, 17.webp; decisiones del usuario del 2026-10-24. | Coordenadas WGS84 verificadas (2026-10-24): https://www.waze.com/es/live-map/directions/sol-de-mayo-jerusalen-arequipa?to=place.w.189072996.1890467817.6000153.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Sol de Mayo' and l.zona = 'yanahuara'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Chaqchao Express', 'cafes_y_postres'::public.lugar_categoria, 'yanahuara'::public.lugar_zona, 'Avenida Ejército 313', '-16.390910'::numeric, '-71.544616'::numeric, 'Lun–Dom: 08:00–22:30', '20.00'::numeric, 'Página oficial (sucursal, dirección y horario): https://www.chaqchao-chocolates.com/contact | Precio: cálculo por persona documentado en Menus/ESTIMADOS_PRECIOS.md y Menus/ChaqchaoExpress/precios_extraidos.json; fuentes: Chaqchao Express Menu.pdf; decisiones del usuario del 2026-10-24. | Coordenadas WGS84 verificadas (2026-10-24): https://www.waze.com/es/live-map/directions/pe/arequipa/yanahuara/chaqchao-express?to=place.ChIJoQAktNBLQpER58dhm1eQxi8.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Chaqchao Express' and l.zona = 'yanahuara'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'BAWi Coffee Shop', 'cafes_y_postres'::public.lugar_categoria, 'yanahuara'::public.lugar_zona, 'Avenida Víctor Andrés Belaúnde 245, Umacollo, Yanahuara', '-16.399075'::numeric, '-71.549342'::numeric, 'Lun–Vie: 08:00–20:00; Sáb–Dom: 09:00–21:00', '22.00'::numeric, 'Revisión 2026-10-24: https://bawicoffeeshop.com/ ; https://www.google.com/maps/place/Bawi+Coffee+Shop/data=!4m6!3m5!1s0x91424b11cafc70e7:0x7518a1bbcb913d31!8m2!3d-16.3990755!4d-71.549342!16s%2Fg%2F11z6t181rz', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'BAWi Coffee Shop' and l.zona = 'yanahuara'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Mirador de Yanahuara', 'entretenimiento_y_cultura'::public.lugar_categoria, 'yanahuara'::public.lugar_zona, 'Plaza de Yanahuara, entre Cuesta del Ángel y Callejón del Cabildo', '-16.387548'::numeric, '-71.541565'::numeric, 'Lun–Dom: 06:00–17:00', '0.00'::numeric, 'MINCETUR, Inventario Nacional de Recursos Turísticos, ficha 597 (ubicación, acceso libre y horario; actualización de ficha: 2024-01-05): https://consultasenlinea.mincetur.gob.pe/fichaInventario/index.aspx?cod_Ficha=597 | Precio de referencia verificado (2026-10-24): https://consultasenlinea.mincetur.gob.pe/fichaInventario/index.aspx?cod_Ficha=597. | Coordenadas WGS84 verificadas (2026-10-24): https://www.waze.com/es/live-map/directions?from=place.w.189072996.1890467817.4768544.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Mirador de Yanahuara' and l.zona = 'yanahuara'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Toro Loco Cayma', 'restaurantes'::public.lugar_categoria, 'cayma'::public.lugar_zona, 'Calle Micaela Bastidas 131, La Tomilla', '-16.360910'::numeric, '-71.544321'::numeric, 'Lun–Dom: 12:00–00:00', '38.00'::numeric, 'Página oficial (restaurante, dirección y horario): https://torolococayma.com/ubicacion | Precio: cálculo por persona documentado en Menus/ESTIMADOS_PRECIOS.md y Menus/ToroLoco/precios_extraidos.json; fuentes: https://torolococayma.com/menu; decisiones del usuario del 2026-10-24. | Coordenadas WGS84 verificadas (2026-10-24): https://www.google.com/maps/place/Toro+Loco+Grill+%26+bar+Cayma/data=!4m6!3m5!1s0x91424b001c745465:0xaeba1169261a8f8e!8m2!3d-16.3609104!4d-71.5443208!16s%2Fg%2F11vzxw_t_p.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Toro Loco Cayma' and l.zona = 'cayma'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Starbucks - Real Plaza Arequipa', 'cafes_y_postres'::public.lugar_categoria, 'cayma'::public.lugar_zona, 'Av. Ejército 1009, C.C. Real Plaza Arequipa, Cayma', '-16.389131'::numeric, '-71.549669'::numeric, 'Lun–Dom: 08:30–22:00', '24.00'::numeric, 'Revisión 2026-10-24: https://www.starbucks.pe/menu/bebidas/cafe-frio ; https://www.starbucks.pe/menu/alimentos/pastries ; https://www.google.com/maps/place/Starbucks+-+Real+Plaza/@-16.389131,-71.549669,17z/data=!3m1!4b1!4m6!3m5!1s0x91424bf2c2ee5a7d:0xce7c8aee091b93e8!8m2!3d-16.389131!4d-71.549669!16s%2Fg%2F11c5bh40__ ; https://www.waze.com/live-map/directions/pe/arequipa/cercado-de-arequipa/starbucks-real-plaza?to=place.ChIJfVruwvJLQpER6JMbCe6KfM4 ; https://www.rappi.com.pe/restaurantes/28426-starbucks', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Starbucks - Real Plaza Arequipa' and l.zona = 'cayma'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Embarcadero 41 - Cayma', 'restaurantes'::public.lugar_categoria, 'cayma'::public.lugar_zona, 'Avenida Ejército 793, interior R-07', '-16.390223'::numeric, '-71.546603'::numeric, 'Lun–Dom: 11:30–22:00', '52.00'::numeric, 'Página oficial (sucursal, dirección y coordenadas del enlace de ubicación): https://www.embarcadero41.com/restaurantes/embarcadero41-cayma/ | Precio: cálculo por persona documentado en Menus/ESTIMADOS_PRECIOS.md y Menus/Embarcadero41/precios_extraidos.json; fuentes: CARTA_Embarcadero41.pdf; decisiones del usuario del 2026-10-24. | Coordenadas WGS84 verificadas (2026-10-24): https://www.google.com/maps/place/Embarcadero+41+Cayma/data=!4m6!3m5!1s0x91424b7bec96e6a1:0x85ca040592b70a62!8m2!3d-16.3902234!4d-71.5466028!16s%2Fg%2F11n989t44f. Se prefiere el pin del negocio Cayma en Google Maps al punto desplazado enlazado por el sitio oficial; se conserva la dirección oficial del catálogo. Horario/estado elegido (2026-10-24): https://es.restaurantguru.com/Embarcadero-41-Arequipa-Arequipa-2.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Embarcadero 41 - Cayma' and l.zona = 'cayma'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Capriccio - Mallplaza Arequipa', 'cafes_y_postres'::public.lugar_categoria, 'cayma'::public.lugar_zona, 'Av. Ejército 793, Mallplaza Arequipa, segundo nivel, Cayma', '-16.390484'::numeric, '-71.546709'::numeric, 'Lun–Dom: 10:00–22:00', '21.00'::numeric, 'Sede y nivel: https://capriccioperu.com/locales/ ; dirección de sede: https://pedidos.capriccioperu.com/locales/ ; carta de cafetería para atención en tienda: https://capriccioperu.com/nuestra-carta/ ; precios de la carta oficial PDF: https://capriccioperu.com/cartas/cafeteria.pdf ; horario y GeoCoordinates del POI Capriccio Mall Plaza en Waze: https://www.waze.com/es/live-map/directions/pe/arequipa/cayma/capriccio-mall-plaza?to=place.ChIJVVVVWEJKQpERcINmHJe5q_s ; horario corroborado: https://es.restaurantguru.com/Capriccio-Arequipa-10', '2026-10-25'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Capriccio - Mallplaza Arequipa' and l.zona = 'cayma'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Cineplanet Arequipa Mall Plaza', 'entretenimiento_y_cultura'::public.lugar_categoria, 'cayma'::public.lugar_zona, 'Avenida Ejército 793, Centro Comercial Mallplaza Arequipa', '-16.390801'::numeric, '-71.546778'::numeric, 'Lun–Dom: 11:00–22:00', '45.00'::numeric, 'Sede Mall Plaza confirmada por el usuario el 2026-10-24. Mallplaza oficial (cine y dirección): https://www.mallplaza.com/pe/arequipa/tiendas/index.html ; https://www.mallplaza.com/pe/arequipa/ ; menú oficial capturado en Menus/CinePlanet/Bebidas.pdf y otros PDF de dulcería el 2026-10-24: https://www.cineplanet.com.pe/compra/0000000037/dulceria?category=8 | Precio: cálculo por persona documentado en Menus/ESTIMADOS_PRECIOS.md y Menus/CinePlanet/precios_extraidos.json; fuentes: Estreno.png, CombosParaUno.pdf; decisiones del usuario del 2026-10-24. | Coordenadas WGS84 verificadas (2026-10-24): https://www.google.com/maps/place/Cineplanet+-+Ej%C3%A9rcito/data=!4m6!3m5!1s0x91424a698d8b5063:0xa14e709b31758dfd!8m2!3d-16.3908011!4d-71.5467778!16s%2Fg%2F1tklrmgb. Horario/estado elegido (2026-10-24): https://www.mallplaza.com/pe/arequipa/tiendas. | Horario general del mall seleccionado por el usuario (consulta 2026-10-25): https://www.mallplaza.com/pe/arequipa/horarios/index.html ; imagen oficial de horarios: https://images.ctfassets.net/gxc4u4llwrnk/6hY51F9oyasZLKn3WjPf0O/66ec7b82733b77ece8060d8b4848c675/Informative_Landing_-_Desktop_-_Opcio%C3%8C_n_13.png . La imagen publica tiendas y patio de comidas 11:00–22:00 todos los días; cine sujeto a cartelera. Esta selección sustituye la referencia anterior a viernes y sábado 13:00–23:00.', '2026-10-25'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Cineplanet Arequipa Mall Plaza' and l.zona = 'cayma'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Palacios Coffee', 'cafes_y_postres'::public.lugar_categoria, 'vallecito'::public.lugar_zona, 'Avenida Lima 201, Vallecito', '-16.402775'::numeric, '-71.542146'::numeric, 'Lun–Sáb: 08:30–20:30; Dom: Cerrado', '6.00'::numeric, 'Página oficial (local y dirección): https://palacioscoffee.com/contacto/ | Precio: cálculo por persona documentado en Menus/ESTIMADOS_PRECIOS.md y Menus/PalaciosCoffee/precios_extraidos.json; fuentes: 2.webp; decisiones del usuario del 2026-10-24. | Coordenadas WGS84 verificadas (2026-10-24): https://www.google.com/maps/place/Palacios+Coffee/data=!4m6!3m5!1s0x91424a58da7c6f13:0x5be80011cc63ebcb!8m2!3d-16.4027753!4d-71.5421461!16s%2Fg%2F11b73xfdhm. Horario/estado elegido (2026-10-24): https://www.google.com/maps/place/Palacios+Coffee/data=!4m6!3m5!1s0x91424a58da7c6f13:0x5be80011cc63ebcb!8m2!3d-16.4027753!4d-71.5421461!16s%2Fg%2F11b73xfdhm.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Palacios Coffee' and l.zona = 'vallecito'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Típika', 'restaurantes'::public.lugar_categoria, 'vallecito'::public.lugar_zona, 'Calle Luna Pizarro 407, Vallecito', '-16.406305'::numeric, '-71.542584'::numeric, 'Lun–Dom: 12:00–17:00', '58.00'::numeric, 'Páginas oficiales: dirección y horario https://tipika.com.pe/reservas/ ; precio del plato https://tipika.com.pe/nuestra-carta/ | Precio de referencia verificado (2026-10-24): https://tipika.com.pe/nuestra-carta/. | Coordenadas WGS84 verificadas (2026-10-24): https://www.google.com/maps/place/Tipika+Restaurant+Turist%C3%ADco/data=!4m6!3m5!1s0x91424af60ac837d3:0x789571b5ee13d54e!8m2!3d-16.4063047!4d-71.5425842!16s%2Fg%2F1vv2t9gv. | Días de atención corroborados (2026-10-25): https://www.waze.com/es/live-map/directions/restaurante-tipika-luna-pizarro-407-arequipa?to=place.w.189072996.1890467815.5726524 ; lunes a domingo 12:00–17:00, misma dirección y teléfono que web oficial.', '2026-10-25'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Típika' and l.zona = 'vallecito'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Fogo Parrilla Brasilera', 'restaurantes'::public.lugar_categoria, 'vallecito'::public.lugar_zona, 'Avenida Lima 574, Vallecito', '-16.407666'::numeric, '-71.543978'::numeric, 'Lun: Cerrado; Mar–Vie: 18:00–22:00; Sáb: 13:00–22:00; Dom: 13:00–16:00', '90.00'::numeric, 'Mesa 24/7 (restaurante, dirección y precio promedio): https://www.mesa247.pe/arequipa/restaurante/fogo-parrilla-brasilera | Precio de referencia verificado (2026-10-24): https://www.mesa247.pe/arequipa/restaurante/fogo-parrilla-brasilera. | Coordenadas WGS84 verificadas (2026-10-24): https://www.google.com/maps/place/Fogo+Parrilla+Brasilera/data=!4m6!3m5!1s0x91424b8a82261c1f:0x8cc722ac322326b4!8m2!3d-16.4076658!4d-71.5439783!16s%2Fg%2F11wy65p32b. Horario/estado elegido (2026-10-24): https://www.google.com/maps/place/Fogo+Parrilla+Brasilera/data=!4m6!3m5!1s0x91424b8a82261c1f:0x8cc722ac322326b4!8m2!3d-16.4076658!4d-71.5439783!16s%2Fg%2F11wy65p32b.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Fogo Parrilla Brasilera' and l.zona = 'vallecito'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Sambambaia’s', 'bares'::public.lugar_categoria, 'vallecito'::public.lugar_zona, 'Calle Luna Pizarro 304, Vallecito', '-16.405601'::numeric, '-71.542030'::numeric, 'Lun–Sáb: 12:00–22:30; Dom: 12:00–17:00', '57.00'::numeric, 'Páginas oficiales: dirección y horario https://sambambaias.com.pe/ ; precio del plato https://sambambaias.com.pe/nuestra-carta | Precio de referencia verificado (2026-10-24): https://sambambaias.com.pe/nuestra-carta. | Coordenadas WGS84 verificadas (2026-10-24): https://www.google.com/maps/place/Sambambaias/data=!4m6!3m5!1s0x91424af61a9a9df7:0x3a2ab94555c20d89!8m2!3d-16.4056015!4d-71.5420303!16s%2Fg%2F1tflyz6v. | Clasificación bares: restaurante con bar completo, Bar/Pub en perfil gestionado por negocio; https://www.tripadvisor.com.pe/Restaurant_Review-g294313-d1086584-Reviews-Sambambaia_s_Restaurant-Arequipa_Arequipa_Region.html. Se conserva precio del plato sin bebida.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Sambambaia’s' and l.zona = 'vallecito'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Museo Naval de Arequipa', 'entretenimiento_y_cultura'::public.lugar_categoria, 'vallecito'::public.lugar_zona, 'Juan Manuel Polar 111, Vallecito', '-16.404526'::numeric, '-71.543073'::numeric, 'Lun–Vie: 09:00–17:00; Sáb: 09:00–14:00', '0.00'::numeric, 'Directorio DePeru (museo, dirección y horario elegido; sin fecha explícita de actualización; gratuidad sin corroborar): https://www.deperu.com/cultural/museos/museo-naval-de-arequipa-4032 | Revisión de precio sin dato utilizable (2026-10-24): https://www.deperu.com/cultural/museos/museo-naval-de-arequipa-4032 ; https://repositorio.cultura.gob.pe/bitstream/handle/CULTURA/1475/Guia%20museos%20e%20instituciones%20museales%202023%20web.pdf?isAllowed=y&sequence=1. | Coordenadas WGS84 verificadas (2026-10-24): https://www.google.com/maps/place/Comandancia+de+la+tercera+zona+naval/data=!4m6!3m5!1s0x91424b85dbbb2b3d:0x1969c3e057943dfc!8m2!3d-16.4045258!4d-71.543073!16s%2Fg%2F11s5nql1n0. Punto del recinto de la Comandancia de la tercera zona naval asociado al museo por referencia del usuario; no ficha independiente de la sala del museo. | Tarifa seleccionada por el usuario (2026-10-24): ingreso libre, S/0; https://www.iperu.org/museo-naval-de-arequipa', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Museo Naval de Arequipa' and l.zona = 'vallecito'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Casa Museo Mario Vargas Llosa', 'entretenimiento_y_cultura'::public.lugar_categoria, 'cercado'::public.lugar_zona, 'Avenida Parra 101', '-16.406670'::numeric, '-71.541010'::numeric, 'Lun–Vie: 08:00–15:45', '20.00'::numeric, 'Gobierno Regional de Arequipa (dirección, tarifas y horario elegido; nota oficial del 2024-12-11): https://www.gob.pe/institucion/regionarequipa/noticias/1073130-gobierno-regional-invita-a-conocer-la-casa-museo-mario-vargas-llosa ; corroboración de tarifas: https://www.tripadvisor.com.mx/Attraction_Review-g294313-d7144344-Reviews-Casa_Museo_Mario_Vargas_Llosa-Arequipa_Arequipa_Region.html | Precio de referencia verificado (2026-10-24): https://www.gob.pe/institucion/regionarequipa/noticias/1073130-gobierno-regional-invita-a-conocer-la-casa-museo-mario-vargas-llosa ; https://www.tripadvisor.com.mx/Attraction_Review-g294313-d7144344-Reviews-Casa_Museo_Mario_Vargas_Llosa-Arequipa_Arequipa_Region.html. | Coordenadas WGS84 verificadas (2026-10-24): https://mapcarta.com/N4336289487.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Casa Museo Mario Vargas Llosa' and l.zona = 'cercado'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Museo La Recoleta', 'entretenimiento_y_cultura'::public.lugar_categoria, 'cercado'::public.lugar_zona, 'Calle La Recoleta 117', '-16.394200'::numeric, '-71.541670'::numeric, 'Mar–Sáb: 09:00–13:00 / 14:30–17:00; Dom: 09:00–13:00', '10.00'::numeric, 'MINCETUR, ficha 982 (distrito Arequipa y horario elegido del museo; ficha actualizada 2024-07-19; tarifa sin reconfirmar): https://consultasenlinea.mincetur.gob.pe/fichaInventario/index.aspx?cod_Ficha=982 ; PROMPERÚ (dirección): https://target2.promperu.gob.pe//destinos/arequipa/centro-historico-de-arequipa/convento-museo-la-recoleta | Precio de referencia verificado (2026-10-24): https://consultasenlinea.mincetur.gob.pe/fichaInventario/index.aspx?cod_Ficha=982. | Coordenadas WGS84 verificadas (2026-10-24): https://mapcarta.com/N873867956.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Museo La Recoleta' and l.zona = 'cercado'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Picantería La Mundial - Local tradicional', 'restaurantes'::public.lugar_categoria, 'cercado'::public.lugar_zona, 'Calle Lucas Poblete 211 y 213, barrio El Filtro', '-16.392687'::numeric, '-71.530016'::numeric, 'Lun–Sáb: 11:00–17:30; Dom: 06:00–17:30', '52.00'::numeric, 'Página oficial (local, dirección y horario): https://www.picanterialamundial.com.pe/PreguntasFrecuentes.html ; menú oficial (dirección del local tradicional): https://picanterialamundial.ola.click/info | Precio: cálculo por persona documentado en Menus/ESTIMADOS_PRECIOS.md y Menus/LaMundial/precios_extraidos.json; fuentes: Nuestra Carta — Picantería La Mundial · Arequipa desde 1933.pdf; decisiones del usuario del 2026-10-24. | Coordenadas WGS84 verificadas (2026-10-24): https://picanterialamundial.ola.click/info.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Picantería La Mundial - Local tradicional' and l.zona = 'cercado'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Parque Selva Alegre', 'entretenimiento_y_cultura'::public.lugar_categoria, 'cercado'::public.lugar_zona, 'Calle Geranios, Arequipa', '-16.389610'::numeric, '-71.530990'::numeric, 'Lun: Cerrado; Mar–Mié, Vie–Sáb: 09:00–18:00; Jue, Dom: 09:00–17:00', '2.00'::numeric, 'Municipalidad Provincial de Arequipa (referencia al parque): https://www.muniarequipa.gob.pe/2026/01/05/conocen-las-vias-alternas-por-cierres-de-la-av-juan-de-la-torre/ ; Wanderlog (dirección y horario elegido; sin fecha explícita de actualización; costo sin corroborar): https://wanderlog.com/es/place/details/1005299/parque-selva-alegre ; RPP (ubicación en Cercado): https://rpp.pe/peru/arequipa/arequipa-hallazgo-de-restos-humanos-calcinados-en-parque-selva-alegre-noticia-1688997 | Precio de referencia verificado (2026-10-24): https://www.muniarequipa.gob.pe/wp-content/uploads/normas-pdf/R2025_00458.pdf ; https://diariocorreo.pe/edicion/arequipa/arequipa-conozca-el-parque-juan-pablo-vizcardo-y-guzman-en-vivo-noticia/?outputType=amp. | Coordenadas WGS84 verificadas (2026-10-24): https://mapcarta.com/es/W198247697.', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Parque Selva Alegre' and l.zona = 'cercado'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Parque Juan Pablo Vizcardo y Guzmán', 'entretenimiento_y_cultura'::public.lugar_categoria, 'cercado'::public.lugar_zona, 'Frente al Parque Selva Alegre, junto al antiguo Hotel de Turistas; JF59+X9C, Arequipa', '-16.390066'::numeric, '-71.531615'::numeric, 'Lun–Mar: Cerrado; Mié–Dom: 09:00–16:00', '0.00'::numeric, 'https://diariocorreo.pe/edicion/arequipa/arequipa-conozca-el-parque-juan-pablo-vizcardo-y-guzman-en-vivo-noticia/ | https://peru21.pe/sites/default/efsfiles/2025-09/pl240925_16.pdf | https://www.google.com/maps/place/Parque+Juan+Pablo+Vizcardo+y+Guzm%C3%A1n/@-16.3900658,-71.5316149,17z/data=!3m1!4b1!4m6!3m5!1s0x91424a4e65a099db:0x7c662b7f0b8fead4!8m2!3d-16.3900658!4d-71.5316149!16s%2Fg%2F11hd8sdhy9 | https://www.waze.com/es/live-map/directions/pe/arequipa/arequipa/parque-juan-pablo-vizcardo-y-guzman?to=place.ChIJ589XgU5KQpERhvxHSnISRJ4', '2026-10-25'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Parque Juan Pablo Vizcardo y Guzmán' and l.zona = 'cercado'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Sophie''s Coffee Nook', 'bares'::public.lugar_categoria, 'yanahuara'::public.lugar_zona, 'Avenida Emmel 129, Yanahuara', '-16.393797'::numeric, '-71.544173'::numeric, 'Lun–Dom: 09:00–21:00', '34.00'::numeric, 'Revisión 2026-10-24: https://www.sophiescoffeenook.com/ ; https://www.sophiescoffeenook.com/carta ; https://www.google.com/maps/place/Sophies+Coffee+Nook/data=!4m6!3m5!1s0x91424bcaa9a7e3d3:0x6453b6d2e1b42b3e!8m2!3d-16.3937969!4d-71.5441728!16s%2Fg%2F11nb7m54rf ; https://es.restaurantguru.com/Sophies-Coffe-Nook-Yanahuara-District', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Sophie''s Coffee Nook' and l.zona = 'yanahuara'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Lounge del Brujo - Cayma', 'bares'::public.lugar_categoria, 'cayma'::public.lugar_zona, 'Urb. Tronco de Oro L1, Cayma', '-16.385511'::numeric, '-71.544078'::numeric, 'Lun–Jue: 13:00–22:00; Vie–Sáb: 13:00–22:30; Dom: 12:30–20:00', '28.00'::numeric, 'Revisión 2026-10-24: https://www.loungedelbrujo.com/?lang=es ; https://linktr.ee/loungedelbrujo ; https://drive.google.com/file/d/180x2026PFr6-9MdhHXLnRxggm59Ie187/view ; https://drive.google.com/file/d/1T3jtRE45yusOSH_p95DiA2j750-Vc679/view ; https://www.google.com/maps/place/Lounge%2Bdel%2BBrujo/@-16.3855114,-71.5466578,17z/data=!4m14!1m7!3m6!1s0x91424b8992769787:0xf7a0cc711818f93f!2sLounge%2Bdel%2BBrujo!8m2!3d-16.3855114!4d-71.5440775!16s%2Fg%2F11j34ghxnd!3m5!1s0x91424b8992769787:0xf7a0cc711818f93f!8m2!3d-16.3855114!4d-71.5440775!16s%2Fg%2F11j34ghxnd', '2026-10-24'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Lounge del Brujo - Cayma' and l.zona = 'cayma'::public.lugar_zona
);

insert into public.lugares (nombre, categoria, zona, direccion, latitud, longitud, horario_atencion, precio_estimado_pen, fuente, fecha_revision)
select 'Páprika Restaurante & Walak Bar - Costa del Sol Arequipa', 'bares'::public.lugar_categoria, 'cercado'::public.lugar_zona, 'Hotel Costa del Sol Wyndham, Plaza Bolívar s/n, urbanización Selva Alegre, Cercado de Arequipa', '-16.389480'::numeric, '-71.532766'::numeric, 'Lun–Dom: 11:30–23:00', '30.00'::numeric, 'Identidad y dirección oficial: https://www.costadelsolperu.com/hoteles/hotel-costa-del-sol-wyndham-arequipa/ ; carta de Páprika Arequipa (sección Cócteles, Mojito S/30): https://paprikarestaurantes.com/paprika-arequipa/ ; horario de Walak: https://www.tripadvisor.com.pe/Restaurant_Review-g294313-d3820845-Reviews-Walak_Bar-Arequipa_Arequipa_Region.html ; distrito Cercado, documento Caja Arequipa de 16/04/2026: https://www.smv.gob.pe/ConsultasP8/temp/Carta%20017-2026%20JGA.pdf ; punto POI Google Maps enlazado desde la dirección oficial: https://www.google.com/maps/place/Hotel+Costa+del+Sol+Arequipa/data=!4m6!3m5!1s0x915b4eb76709c847:0xd5f60b7d67b90e4!8m2!3d-16.3894804!4d-71.5327662!16s%2Fg%2F1vf9dfk4', '2026-10-25'::date
where not exists (
  select 1 from public.lugares l
  where l.nombre = 'Páprika Restaurante & Walak Bar - Costa del Sol Arequipa' and l.zona = 'cercado'::public.lugar_zona
);

commit;
