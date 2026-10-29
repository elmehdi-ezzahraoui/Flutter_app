-- ============================================================
-- EcoCity – Supabase setup: notifications & report_likes
-- ============================================================

-- ─── Table notifications ────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID         REFERENCES auth.users(id) ON DELETE CASCADE,
  type        TEXT         NOT NULL DEFAULT 'new_report',  -- 'new_report' | 'status_change' | 'upvote'
  title       TEXT         NOT NULL,
  body        TEXT,
  report_id   UUID         REFERENCES public.reports(id) ON DELETE CASCADE,
  is_read     BOOLEAN      NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Un utilisateur voit ses notifications personnelles et les notifications globales
DROP POLICY IF EXISTS "Voir ses notifications" ON public.notifications;
DROP POLICY IF EXISTS "Créer notification" ON public.notifications;
DROP POLICY IF EXISTS "Marquer comme lu" ON public.notifications;
DROP POLICY IF EXISTS "Supprimer ses notifications" ON public.notifications;

CREATE POLICY "Voir ses notifications" ON public.notifications FOR SELECT USING (user_id IS NULL OR auth.uid() = user_id);
CREATE POLICY "Créer notification"     ON public.notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Marquer comme lu"       ON public.notifications FOR UPDATE USING (user_id IS NULL OR auth.uid() = user_id);
CREATE POLICY "Supprimer ses notifications" ON public.notifications FOR DELETE USING (user_id IS NULL OR auth.uid() = user_id);

ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- ─── RPC : incrémenter upvote ────────────────────────────────
-- Utilise la colonne upvotes déjà existante dans public.reports

CREATE OR REPLACE FUNCTION public.increment_upvote(p_report_id UUID)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE public.reports
    SET upvotes    = upvotes + 1,
        updated_at = NOW()
  WHERE id = p_report_id
  RETURNING upvotes INTO v_count;
  RETURN v_count;
END;
$$;

-- ─── RPC : notifier les autres utilisateurs ──────────────────

CREATE OR REPLACE FUNCTION public.notify_users_new_report(
  p_report_id UUID,
  p_report_title TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Notifie l'utilisateur qui a créé le signalement (confirmation)
  IF auth.uid() IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, type, title, body, report_id)
    VALUES (
      auth.uid(),
      'new_report',
      '✅ Signalement publié',
      'Votre signalement "' || p_report_title || '" est maintenant visible sur la carte.',
      p_report_id
    );
  END IF;

  -- 2. Notifie tous les autres utilisateurs enregistrés
  INSERT INTO public.notifications (user_id, type, title, body, report_id)
  SELECT
    u.id,
    'new_report',
    '🔴 Nouveau signalement',
    p_report_title,
    p_report_id
  FROM auth.users u
  WHERE u.id != auth.uid();
END;
$$;

-- ─── Trigger : notification changement de statut ─────────────

CREATE OR REPLACE FUNCTION public.notify_report_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.user_id IS NOT NULL THEN
    INSERT INTO public.notifications(user_id, type, title, body, report_id)
    VALUES (
      NEW.user_id,
      'status_change',
      CASE NEW.status
        WHEN 'en_cours' THEN '🟠 Signalement pris en charge'
        WHEN 'resolu'   THEN '🟢 Signalement résolu'
        ELSE '🔔 Statut mis à jour'
      END,
      NEW.title,
      NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_report_status_notification ON public.reports;
CREATE TRIGGER trg_report_status_notification
AFTER UPDATE ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.notify_report_status_change();
