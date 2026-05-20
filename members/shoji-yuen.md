---
title: 結縁祥治
permalink: /members/shoji-yuen/
---

<section class="page-header">
  <p class="eyebrow">Member</p>
  <h1>結縁祥治</h1>
  <p>教授</p>
</section>

<section class="section member-profile">
  {% assign member = site.data.members | where: "slug", "shoji-yuen" | first %}
  {% if member.photo_url %}
    <img class="profile-photo" src="{{ member.photo_url }}" alt="{{ member.name }}">
  {% else %}
    <div class="avatar avatar--large" aria-hidden="true">SY</div>
  {% endif %}
  <div class="member-profile__body">
    {% if member.website or member.profile_md_url %}
      <div class="profile-block profile-block--compact">
        <p class="eyebrow">Links</p>
        {% if member.website %}
          <p><strong>個人ページ</strong><br><a class="button" href="{{ member.website }}">個人ページを開く</a></p>
        {% endif %}
        {% if member.profile_md_url %}
          <p><strong>profile</strong><br><a class="button" href="{{ member.profile_md_url }}">profileを開く</a></p>
        {% endif %}
      </div>
    {% else %}
      <div class="profile-block">
        <p class="eyebrow">Research Theme</p>
        <h2>可逆並行プログラミング，実時間ソフトウェア</h2>
        <p>可逆計算、並行プログラミング、実時間ソフトウェアの形式的手法に関心があります。プログラムの正しさや信頼性を数理的に保証するための理論と開発支援手法を研究しています。</p>
      </div>
      <div class="profile-block profile-block--compact">
        <p class="eyebrow">Contact</p>
        <p><strong>メール</strong><br>yuen [at] sqlab.jp</p>
      </div>
    {% endif %}
    <a class="back-link" href="{{ '/members/' | relative_url }}">メンバー一覧へ</a>
  </div>
</section>
