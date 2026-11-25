-- CUADRA · Esquema inicial
-- Aplicar desde el editor SQL de Supabase (o con la CLI de Supabase).
-- Los montos se guardan en pesos chilenos, sin decimales.

-- 1. Tipos ---------------------------------------------------------------
create type public.tipo_movimiento as enum ('gasto', 'ingreso');
create type public.origen_movimiento as enum ('foto_ia', 'corregido', 'manual');

-- 2. Categorías (compartidas para todos los usuarios) ---------------------
create table public.categorias (
  id      smallint generated always as identity primary key,
  nombre  text not null unique,
  tipo    public.tipo_movimiento not null
);

insert into public.categorias (nombre, tipo) values
  ('Alimentación',        'gasto'),
  ('Servicios básicos',   'gasto'),
  ('Salud',               'gasto'),
  ('Transporte',          'gasto'),
  ('Hogar',               'gasto'),
  ('Educación',           'gasto'),
  ('Entretenimiento',     'gasto'),
  ('Otros gastos',        'gasto'),
  ('Sueldo',              'ingreso'),
  ('Abono por transferencia', 'ingreso'),
  ('Otros ingresos',      'ingreso');

-- 3. Movimientos ---------------------------------------------------------
create table public.movimientos (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  tipo          public.tipo_movimiento not null,
  comercio      text not null,
  concepto      text,
  fecha         date not null,
  monto         integer not null check (monto > 0),
  categoria_id  smallint references public.categorias (id),
  origen        public.origen_movimiento not null default 'foto_ia',
  -- Confianza de la IA por campo (0 a 1). Nula si el movimiento fue manual.
  confianza     jsonb,
  -- Ruta de la imagen en el almacenamiento (puede quedar nula si se descarta).
  imagen_path   text,
  created_at    timestamptz not null default now()
);

create index movimientos_usuario_fecha_idx
  on public.movimientos (user_id, fecha desc);

-- 4. Seguridad a nivel de fila (cada persona solo ve lo suyo) -------------
alter table public.movimientos enable row level security;
alter table public.categorias  enable row level security;

create policy "categorias: lectura para usuarios autenticados"
  on public.categorias for select
  to authenticated
  using (true);

create policy "movimientos: ver los propios"
  on public.movimientos for select
  to authenticated
  using (user_id = auth.uid());

create policy "movimientos: crear los propios"
  on public.movimientos for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "movimientos: editar los propios"
  on public.movimientos for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "movimientos: eliminar los propios"
  on public.movimientos for delete
  to authenticated
  using (user_id = auth.uid());

-- 5. Saldo: aritmética exacta en la base de datos (no la calcula la IA) ---
create view public.saldo_usuario
with (security_invoker = true) as
select
  user_id,
  sum(case tipo when 'ingreso' then monto else -monto end)::bigint as saldo
from public.movimientos
group by user_id;

-- Gasto por categoría del mes en curso
create view public.gasto_mensual_por_categoria
with (security_invoker = true) as
select
  m.user_id,
  c.nombre as categoria,
  sum(m.monto)::bigint as total
from public.movimientos m
join public.categorias c on c.id = m.categoria_id
where m.tipo = 'gasto'
  and date_trunc('month', m.fecha) = date_trunc('month', current_date)
group by m.user_id, c.nombre;

-- 6. Aviso de posible duplicado (mismo comercio, fecha y monto) ------------
create or replace function public.posible_duplicado(
  p_comercio text,
  p_fecha    date,
  p_monto    integer
) returns boolean
language sql
stable
security invoker
as $$
  select exists (
    select 1
    from public.movimientos
    where user_id = auth.uid()
      and lower(comercio) = lower(p_comercio)
      and fecha = p_fecha
      and monto = p_monto
  );
$$;

-- 7. Almacenamiento privado de comprobantes -------------------------------
insert into storage.buckets (id, name, public)
values ('comprobantes', 'comprobantes', false)
on conflict (id) do nothing;

-- Cada persona solo accede a la carpeta con su propio id: <user_id>/archivo.jpg
create policy "comprobantes: subir en la carpeta propia"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'comprobantes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "comprobantes: ver los propios"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'comprobantes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "comprobantes: eliminar los propios"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'comprobantes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
