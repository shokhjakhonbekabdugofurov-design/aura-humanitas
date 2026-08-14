/* Aura Humanitas — live public data layer
   Keeps the existing HTML/CSS design intact and only replaces content inside
   the already-existing Current Issue and Archives containers when Supabase is configured.
*/
(function(){
  const C=window.AURA_CONFIG||{};
  const configured=C.SUPABASE_URL && !C.SUPABASE_URL.includes('YOUR_') && C.SUPABASE_KEY && !C.SUPABASE_KEY.includes('YOUR_');
  if(!configured || !window.supabase) return;
  const sb=window.supabase.createClient(C.SUPABASE_URL,C.SUPABASE_KEY);
  const esc=v=>String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
  const dateValue=x=>x.issue_date||x.publication_date||`${x.year||''}-01-01`;
  const monthName=x=>new Intl.DateTimeFormat('en',{month:'long',year:'numeric'}).format(new Date(dateValue(x)+'T00:00:00'));
  const thumb=['one','two','three','four','five','six'];

  async function load(){
    const issueRes=await sb.from('issues').select('id,volume,issue_number,issue_date,title,description,cover_path,full_issue_pdf_path,published').eq('published',true).gte('issue_date','2026-01-01').order('issue_date',{ascending:false}).limit(1).maybeSingle();
    if(issueRes.error){ console.error('Current issue load failed:', issueRes.error); return; }
    if(!issueRes.data) return;
    const issue=issueRes.data;

    const articleRes=await sb.from('articles')
      .select('id,title,author_name,university,field,abstract,keywords,pages,doi,published,created_at')
      .eq('issue_id',issue.id).eq('published',true).order('created_at',{ascending:false});
    if(articleRes.error){ console.error('Published articles load failed:', articleRes.error); return; }
    const articles=articleRes.data||[];

    const issueSection=document.querySelector('#issue');
    if(issueSection){
      const info=issueSection.querySelector('.issue-info');
      if(info){
        const cells=info.querySelectorAll('div');
        if(cells[0]) cells[0].querySelector('strong').textContent=issue.volume||'—';
        if(cells[1]) cells[1].querySelector('strong').textContent=issue.issue_number||'—';
        if(cells[2]) cells[2].querySelector('strong').textContent=monthName(issue);
      }
      const kicker=issueSection.querySelector('.section-head .kicker');
      if(kicker) kicker.textContent=monthName(issue);
      const grid=issueSection.querySelector('.grid');
      if(info){
        let issueDownload=issueSection.querySelector('.live-issue-download');
        if(!issueDownload){
          issueDownload=document.createElement('div');
          issueDownload.className='live-issue-download';
          issueDownload.style.cssText='margin:0 0 25px;display:flex;gap:10px;flex-wrap:wrap';
          issueSection.querySelector('.container')?.insertBefore(issueDownload, grid || info.nextSibling);
        }
        if(issue.full_issue_pdf_path){
          issueDownload.innerHTML=`<a class="btn" href="issue/index.html?id=${encodeURIComponent(issue.id)}">Download Full Issue PDF →</a>`;
        }else{
          issueDownload.innerHTML='';
        }
      }

      if(grid){
        grid.innerHTML=articles.length ? articles.map((a,i)=>{
          const keywords=Array.isArray(a.keywords)?a.keywords.join(', '):String(a.keywords||'');
          const desc=a.abstract ? String(a.abstract).replace(/\s+/g,' ').slice(0,180)+(a.abstract.length>180?'…':'') : 'Research article published in the current issue of Aura Humanitas.';
          return `<article class="card">
            <div class="thumb ${thumb[i%thumb.length]}"><span class="thumb-label">${esc(a.field||'Humanities')}</span></div>
            <div class="card-body">
              <div class="tag">Research Article</div>
              <h3>${esc(a.title)}</h3>
              <p>${esc(desc)}</p>
              <div class="card-meta"><span>${esc(a.author_name)}</span><span>${a.pages?`pp. ${esc(a.pages)}`:'Article'}</span></div>
              <a class="read" href="article/index.html?id=${encodeURIComponent(a.id)}">Read Article →</a>
            </div>
          </article>`;
        }).join('') : '<article class="card"><div class="card-body"><div class="tag">Current Issue</div><h3>No published articles yet</h3><p>Published articles assigned to this issue will appear here.</p></div></article>' ;
      }
    }

    const heroKicker=document.querySelector('.hero .kicker');
    if(heroKicker) heroKicker.textContent=`Volume ${issue.volume} · Issue ${issue.issue_number} · ${monthName(issue)}`;
    const coverSmall=document.querySelector('.journal-cover small');
    if(coverSmall) coverSmall.textContent=`AURA HUMANITAS · VOL. ${issue.volume} · ISSUE ${issue.issue_number}`;
    const coverDate=document.querySelector('.journal-cover p:last-child');
    if(coverDate) coverDate.textContent=monthName(issue);

    const archiveList=document.querySelector('.archive-list');
    if(archiveList){
      const allRes=await sb.from('issues').select('id,volume,issue_number,issue_date,title,description,cover_path,full_issue_pdf_path,published').eq('published',true).gte('issue_date','2026-01-01').order('issue_date',{ascending:false});
      if(!allRes.error){
        const all=allRes.data||[];
        archiveList.innerHTML=all.length ? all.map(x=>`<div class="archive-row">
          <div><h3>Volume ${esc(x.volume)} · Issue ${esc(x.issue_number)}</h3><p>${esc(x.title||monthName(x.issue_date))}</p></div>
          <span class="badge">${new Date(dateValue(x)+'T00:00:00').getFullYear()}</span>
        </div>`).join('') : '<div class="archive-row"><div><h3>No published issues yet</h3><p>Published monthly issues will appear here.</p></div></div>';
      }
    }
  }
  document.addEventListener('DOMContentLoaded',load);
})();
