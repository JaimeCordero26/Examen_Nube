#!/bin/bash

echo "🚀 Obteniendo la clave de cifrado desde el Secret de Kubernetes..."

# 1. Obtiene la clave del Secret y la decodifica de Base64
ENCRYPTION_KEY=$(kubectl get secret encryption-key-secret -o jsonpath='{.data.key}' | base64 --decode)

# Comprueba si la clave se obtuvo correctamente
if [ -z "$ENCRYPTION_KEY" ]; then
    echo "❌ Error: No se pudo obtener la clave de cifrado del Secret 'encryption-key-secret'."
    exit 1
fi

echo "🔑 Clave obtenida. Conectando a la base de datos..."

# 2. Obtiene el nombre del pod de PostgreSQL
POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# 3. Ejecuta el SQL, pasando la clave como una variable a psql
kubectl exec -i $POD_NAME -- psql -U admin -d cafeboreal -v "key=${ENCRYPTION_KEY}" <<EOF

-- Primero, limpia las tablas para evitar duplicados, en el orden correcto
DELETE FROM order_items;
DELETE FROM orders;
DELETE FROM customers;
DELETE FROM products;

-- Insertar 50 Productos (semillas)
INSERT INTO products (name, description, price, stock, image_url) VALUES
('Café Boreal Clásico', 'Mezcla de la casa, balanceado y suave.', 8.50, 200, 'images/classic.jpg'),
('Expreso Intenso', 'Tueste oscuro para un sabor profundo y persistente.', 10.00, 150, 'images/espresso.jpg'),
('Amanecer Tropical', 'Notas frutales y cítricas, ideal para métodos de filtro.', 12.75, 80, 'images/tropical.jpg'),
('Tesoro de Tarrazú', 'Cuerpo completo, acidez brillante y aroma a chocolate.', 15.00, 120, 'images/tarrazu.jpg'),
('Misterio de Monteverde', 'Café de altura con notas florales y silvestres.', 14.50, 70, 'images/monteverde.jpg'),
('Brisa del Pacífico', 'Tueste medio con un toque salino y acaramelado.', 11.00, 90, 'images/pacific.jpg'),
('Fuerza Volcánica', 'Sabor ahumado y terroso, de las faldas del volcán.', 13.25, 110, 'images/volcano.jpg'),
('Caramelo Dorado', 'Infusionado naturalmente con notas de caramelo.', 9.75, 180, 'images/caramel.jpg'),
('Vainilla Francesa', 'Un toque dulce y cremoso de vainilla de la más alta calidad.', 9.75, 175, 'images/vanilla.jpg'),
('Descafeinado Suizo', 'Proceso de agua suiza, sin químicos, sabor completo.', 10.50, 60, 'images/decaf.jpg'),
('Grano de Miel', 'Proceso "honey", dulzura natural y cuerpo sedoso.', 16.00, 50, 'images/honey.jpg'),
('Cereza Negra', 'Notas distintivas a cereza negra y cacao.', 13.80, 75, 'images/cherry.jpg'),
('Nuez Tostada', 'Aroma y sabor a nueces recién tostadas.', 9.75, 160, 'images/nut.jpg'),
('Peaberry Premium', 'Grano redondo y raro, sabor más concentrado.', 18.00, 40, 'images/peaberry.jpg'),
('Orgánico de la Selva', 'Cultivado a la sombra, certificado orgánico.', 12.50, 100, 'images/organic.jpg'),
('Reserva del Fundador', 'La mejor selección de granos de la cosecha anual.', 25.00, 30, 'images/reserve.jpg'),
('Mezcla Navideña', 'Edición limitada con notas a canela y nuez moscada.', 11.50, 0, 'images/christmas.jpg'),
('Sol de Verano', 'Tueste ligero, perfecto para café helado.', 10.25, 130, 'images/summer.jpg'),
('Sombra de Roble', 'Madurado en barriles de roble, notas a whisky.', 19.50, 45, 'images/oak.jpg'),
('Corazón de Colombia', 'Clásico sabor colombiano, balanceado y frutal.', 12.00, 140, 'images/colombia.jpg'),
('Alma de Brasil', 'Cuerpo suave, baja acidez, notas a chocolate y nuez.', 11.80, 135, 'images/brazil.jpg'),
('Espíritu de Etiopía', 'Cuna del café, notas a arándano y flores.', 14.75, 85, 'images/ethiopia.jpg'),
('Tueste Italiano', 'Extra oscuro, ideal para un ristretto potente.', 10.75, 125, 'images/italian.jpg'),
('Tueste Francés', 'Oscuro y aceitoso, con un sabor intenso y ahumado.', 10.75, 115, 'images/french.jpg'),
('Añejo Especial', 'Granos envejecidos para un sabor suave y complejo.', 22.00, 35, 'images/aged.jpg'),
('Bomba de Cafeína', 'Mezcla especial con un extra de cafeína natural.', 11.25, 95, 'images/caffeine.jpg'),
('Moca Chocolate', 'Infusionado con cacao oscuro de alta calidad.', 9.75, 155, 'images/mocha.jpg'),
('Crema Irlandesa', 'Sabor a licor de crema irlandesa, sin alcohol.', 9.75, 145, 'images/irish.jpg'),
('Té de Cáscara', 'Infusión hecha de la cáscara seca del café.', 7.00, 55, 'images/cascara.jpg'),
('Gourmet Geisha', 'Variedad exótica, perfil de sabor complejo y delicado.', 35.00, 20, 'images/geisha.jpg'),
('Perla Negra', 'Tueste oscuro brillante, notas a melaza y anís.', 13.50, 65, 'images/pearl.jpg'),
('Amanecer Dorado', 'Tueste rubio, alta acidez y notas cítricas.', 12.25, 78, 'images/blonde.jpg'),
('Beso de Avellana', 'Sabor clásico y reconfortante a avellana tostada.', 9.75, 165, 'images/hazelnut.jpg'),
('Rayo Matutino', 'Mezcla diseñada para empezar el día con energía.', 9.00, 190, 'images/morning.jpg'),
('Serenidad Nocturna', 'Descafeinado con manzanilla para relajarse.', 11.00, 58, 'images/serenity.jpg'),
('Vigor de Kenia', 'Acidez vinosa y notas a frutos rojos.', 14.25, 88, 'images/kenya.jpg'),
('Tierra de Sumatra', 'Sabor terroso, cuerpo pesado y baja acidez.', 13.75, 92, 'images/sumatra.jpg'),
('Magia de Guatemala', 'Balance perfecto entre dulzura y acidez, notas a cacao.', 13.00, 105, 'images/guatemala.jpg'),
('El Conquistador', 'Mezcla de granos de Perú, sabor audaz.', 12.80, 98, 'images/peru.jpg'),
('Finca La Esmeralda', 'Microlote especial, notas a jazmín y bergamota.', 28.00, 25, 'images/esmeralda.jpg'),
('Néctar Divino', 'Proceso natural, notas a fresa y frutos tropicales.', 17.50, 48, 'images/nectar.jpg'),
('Ébano Real', 'El más oscuro de nuestros tuestes, intenso y puro.', 11.75, 111, 'images/ebony.jpg'),
('Brisa Costeña', 'Café de baja altura, suave y con notas a nuez.', 10.50, 123, 'images/coastal.jpg'),
('Ritmo Caribeño', 'Toques de ron y coco en una mezcla suave.', 12.00, 82, 'images/caribbean.jpg'),
('Secreto del Monje', 'Mezcla secreta con especias dulces.', 13.25, 77, 'images/monk.jpg'),
('Polvo de Estrellas', 'Café molido extrafino para café turco.', 10.00, 68, 'images/turkish.jpg'),
('Luz de Luna', 'Tueste medio-claro, perfecto para la tarde.', 9.50, 133, 'images/moonlight.jpg'),
('Canto del Quetzal', 'Notas a chocolate, caramelo y cítricos de Chiapas.', 14.00, 91, 'images/quetzal.jpg'),
('Oro Azteca', 'Mezcla mexicana con un toque de canela.', 12.50, 89, 'images/aztec.jpg'),
('Corazón Maya', 'Café de Honduras, cuerpo cremoso y final dulce.', 13.50, 93, 'images/mayan.jpg');

-- Insertar 10 Clientes (semillas) usando la clave correcta pasada como variable (:'key')
INSERT INTO customers (full_name, email, identity_number) VALUES
('Elena Rojas', 'elena.rojas@email.com', pgp_sym_encrypt('111222333', :'key')),
('Carlos Gutiérrez', 'carlos.g@email.com', pgp_sym_encrypt('222333444', :'key')),
('Sofía Mora', 'sofia.mora@email.com', pgp_sym_encrypt('333444555', :'key')),
('Mateo Vargas', 'mateo.vargas@email.com', pgp_sym_encrypt('444555666', :'key')),
('Valentina Solano', 'valentina.s@email.com', pgp_sym_encrypt('555666777', :'key')),
('Javier Núñez', 'javier.nunez@email.com', pgp_sym_encrypt('666777888', :'key')),
('Camila Salazar', 'camila.s@email.com', pgp_sym_encrypt('777888999', :'key')),
('Andrés Jiménez', 'andres.j@email.com', pgp_sym_encrypt('888999000', :'key')),
('Lucía Castro', 'lucia.castro@email.com', pgp_sym_encrypt('999000111', :'key')),
('David Herrera', 'david.h@email.com', pgp_sym_encrypt('000111222', :'key'));

-- Insertar Órdenes de ejemplo
-- Nota: Obtenemos los IDs de clientes y productos con subconsultas para asegurar la integridad.

-- Orden 1 para Elena Rojas (ID=1)
INSERT INTO orders (customer_id, total_amount) VALUES (1, 33.50);
INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
(1, (SELECT id FROM products WHERE name = 'Tesoro de Tarrazú'), 1, 15.00),
(1, (SELECT id FROM products WHERE name = 'Expreso Intenso'), 1, 10.00),
(1, (SELECT id FROM products WHERE name = 'Café Boreal Clásico'), 1, 8.50);

-- Orden 2 para Carlos Gutiérrez (ID=2)
INSERT INTO orders (customer_id, total_amount) VALUES (2, 21.00);
INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
(2, (SELECT id FROM products WHERE name = 'Brisa del Pacífico'), 2, 11.00);

-- Orden 3 para Sofía Mora (ID=3)
INSERT INTO orders (customer_id, total_amount) VALUES (3, 60.00);
INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
(3, (SELECT id FROM products WHERE name = 'Reserva del Fundador'), 2, 25.00),
(3, (SELECT id FROM products WHERE name = 'Expreso Intenso'), 1, 10.00);


EOF

echo "✅ Base de datos poblada exitosamente con 50 productos, 10 clientes y 3 órdenes."
