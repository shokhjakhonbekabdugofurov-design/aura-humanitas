
/*
AURA HUMANITAS — PHASE 3 PUBLIC INTEGRATION
This helper does NOT redesign the existing interface.

Use it from the existing index.html only where the current article cards should become live.
The visual classes can stay exactly as they are.

Example:
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="config.js"></script>
<script src="phase3_public_integration.js"></script>

Then call:
AuraLive.loadCurrentIssue("#your-existing-grid");
AuraLive.loadArchives("#your-existing-archive-container");

The helper fills existing containers with database content. If your current
markup must remain pixel-identical, map only the text/href values to your
existing elements rather than replacing the CSS.
*/
window.AuraLive = {
  async loadCurrentIssue(selector){
    const root=document.querySelector(selector); if(!root)return;
    const C=window.AURA_CONFIG||{};
    const sb=window.supabase.createClient(C.SUPABASE_URL,C.SUPABASE_KEY);
    const {data:issue}=await sb.from("issues").select("id,volume,issue_number,title,issue_date").eq("published",true).order("issue_date",{ascending:false}).limit(1).maybeSingle();
    if(!issue)return;
    const {data:articles}=await sb.from("articles").select("id,title,author_name,field,abstract,published").eq("issue_id",issue.id).eq("published",true).order("created_at",{ascending:false});
    return {issue,articles:articles||[]};
  },
  async loadArchives(selector){
    const root=document.querySelector(selector); if(!root)return;
    const C=window.AURA_CONFIG||{};
    const sb=window.supabase.createClient(C.SUPABASE_URL,C.SUPABASE_KEY);
    const {data}=await sb.from("issues").select("*").eq("published",true).order("issue_date",{ascending:false});
    return data||[];
  }
};
