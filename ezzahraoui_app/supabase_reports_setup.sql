-- ============================================================
-- EcoCity — Script SQL Supabase
-- À exécuter dans l'éditeur SQL de votre dashboard Supabase
-- ============================================================

-- 1. Créer la table des signalements
CREATE TABLE IF NOT EXISTS public.reports (
  id          UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID             REFERENCES auth.users(id) ON DELETE SET NULL,
  title       TEXT             NOT NULL,
  description TEXT,
  category    TEXT             NOT NULL DEFAULT 'autre',
  latitude    DOUBLE PRECISION NOT NULL,
  longitude   DOUBLE PRECISION NOT NULL,
  status      TEXT             NOT NULL DEFAULT 'signale'
                CHECK (status IN ('signale', 'en_cours', 'resolu')),
  upvotes     INTEGER          NOT NULL DEFAULT 0,
  image_url   TEXT,
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

-- 2. Activer Row Level Security (RLS)
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- 3. Politique : lecture publique (tout le monde peut voir la carte)
CREATE POLICY "Lecture publique des signalements"
  ON public.reports
  FOR SELECT
  USING (true);

-- 4. Politique : création par utilisateurs authentifiés
CREATE POLICY "Création par utilisateur connecté"
  ON public.reports
  FOR INSERT 
  WITH CHECK (auth.uid() IS NOT NULL);

-- 5. Politique : mise à jour par utilisateurs authentifiés
CREATE POLICY "Mise à jour par utilisateur connecté"
  ON public.reports
  FOR UPDATE
  USING (auth.uid() IS NOT NULL);

-- 6. Politique : suppression par le propriétaire
CREATE POLICY "Suppression par le propriétaire"
  ON public.reports
  FOR DELETE
  USING (auth.uid() = user_id);

-- 7. Activer Realtime pour la table (nécessaire pour les mises à jour live)
-- Via le dashboard : Database → Replication → cochez "reports"
-- Ou via SQL :
ALTER PUBLICATION supabase_realtime ADD TABLE public.reports;

-- 8. Données de démonstration (optionnel - Casablanca / Berrechid)
INSERT INTO public.reports (title, description, category, latitude, longitude, status, upvotes) VALUES
  ('Dépôt sauvage Bd Mohammed V', 'Plusieurs sacs de plastique abandonnés', 'dépôt sauvage', 33.5892, -7.6028, 'signale', 5),
  ('Poubelle débordante Marché Central', 'La poubelle n''a pas été vidée depuis 3 jours', 'poubelle débordante', 33.5910, -7.6045, 'en_cours', 12),
  ('Zone propre Parc de la Ligue Arabe', 'Nettoyage terminé par les bénévoles', 'zone polluée', 33.5975, -7.6283, 'resolu', 8),
  ('Déchets plastiques Corniche', 'Bouteilles et sachets sur la plage', 'déchets plastiques', 33.5950, -7.6350, 'signale', 3);
