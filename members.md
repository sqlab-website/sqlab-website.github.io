---
title: メンバー
permalink: /members/
---

<section class="page-header">
  <p class="eyebrow">Members</p>
  <h1>メンバー</h1>
  <p>研究室の構成員です。氏名やテーマは`_data/members.yml`から更新できます。</p>
</section>

<section class="section">
  <div class="member-grid">
    {% for member in site.data.members %}
      <article class="member-card">
        <div class="avatar" aria-hidden="true">{{ member.initial }}</div>
        <p class="eyebrow">{{ member.role }}</p>
        <h2>{{ member.name }}</h2>
        <p>{{ member.theme }}</p>
        {% if member.slug %}
          <a class="member-card__link" href="{{ '/members/' | append: member.slug | append: '/' | relative_url }}">個人ページ</a>
        {% endif %}
      </article>
    {% endfor %}
  </div>
</section>
