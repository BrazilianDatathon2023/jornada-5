from dash import Dash, html, dcc, callback, Output, Input, State
import dash_bootstrap_components as dbc
import plotly.express as px
import numpy as np
import geopandas as gpd
import pandas as pd
import pydeck as pdk
import dash_deck
import math

mapbox_api_token = "pk.eyJ1IjoiZ2FicmllbHktcGVyZWlyYSIsImEiOiJjbDZtY29laGwwazd0M2tvMHV3eW1tZGdiIn0.oxNJKT1B1Px1ZrmDnkr-5g"

app = Dash(__name__, title='Malformação Congênita', external_stylesheets=[dbc.themes.LUX])

app.layout = html.Div([
    html.Br(),
    html.H1(children='Malformação Congênita no Brasil', style={'textAlign':'center'}),
    html.P(children='Um painel interativo para análise espaço-temporal dos casos e óbitos por malformações congênitas no Brasil', style={'textAlign':'center'}),
    html.Br(),

    dbc.Row(
            [
                #dbc.Col(dcc.Dropdown(['Casos_entre_nascidos','Espinha bífida','Outras malformações congênitas do sistema nervoso','Malformações congênitas do aparelho circulatório','Fenda labial e fenda palatina','Ausência atresia e estenose do intestino delgado','Outras malformações congênitas do aparelho digestivo','Testiculo não-descido','Outras malformações do aparelho geniturinário','Deformidades congênitas do quadril','Deformidades congênitas dos pés','Outras malformações e deformidades congênitas do aparelho osteomuscular','Outras malformações congênitas','Anomalias cromossômicas não classificadas em outra parte'], 'Casos_entre_nascidos', id='tipo_malformacao')),
                dcc.Slider(2017, 2020, step=1, id='ano', marks={2016: '2016', 2017: '2017', 2018: '2018', 2019: '2019', 2020: '2020'}, value=2019),
                #dbc.Col(dbc.Button("Filtrar", id='submit', color="primary", n_clicks=0))
            ]
    ),
    
    dbc.Row(
            [      
                html.Br(),  
                dbc.Col([html.P("Proporção de casos de malformações congênitas pelo total de nascidos"), html.Br(),
                        html.Div(id='mapa_content')]),
                dbc.Col([
                        html.P("Proporção de estabelecimentos habilitados para gravidez de alto risco pelo total de nascidos"),
                        html.Div(id="mapa_cnes_content")]),
                dcc.Graph(id='bar_content')
            ]
    ),
    html.Br(),

], className='container')


def color_scale(valor, max_value, min_value):
    colors=[[255,255,204],
            [255,255,204],
            [255,237,160],
            [254,217,118],
            [254,178,76],
            [253,141,60],
            [252,78,42],
            [227,26,28],
            [189,0,38],
            [128,0,38],
            [128,0,38]]

    index = (valor-min_value)/(max_value-min_value)

    return colors[int(index*10//1)]

def color_scale_hosp(valor, max_value, min_value):
    colors=[[255,255,217],
            [255,255,217],
            [237,248,177],
            [199,233,180],
            [127,205,187],
            [65,182,196],
            [29,145,192],
            [34,94,168],
            [37,52,148],
            [8,29,88],
            [8,29,88]]

    index = (valor-min_value)/(max_value-min_value)

    return colors[int(index*10//1)]



def get_map_layer(ano):
    gdf = gpd.read_file("./data/shapes/estados_2010.dbf")

    df = pd.read_csv("./data/tabela_malformacao_%s.csv"%str(ano))


    for col in ['Casos_entre_nascidos','Espinha bífida','Outras malformações congênitas do sistema nervoso','Malformações congênitas do aparelho circulatório','Fenda labial e fenda palatina','Ausência atresia e estenose do intestino delgado','Outras malformações congênitas do aparelho digestivo','Testiculo não-descido','Outras malformações do aparelho geniturinário','Deformidades congênitas do quadril','Deformidades congênitas dos pés','Outras malformações e deformidades congênitas do aparelho osteomuscular','Outras malformações congênitas','Anomalias cromossômicas não classificadas em outra parte']:
        df[col] *= 100
        df[col] = df[col].round(2)

    gdf = gdf.merge(df[['UF', 'Estado', 'Casos_entre_nascidos']], how='left', left_on=['sigla'], right_on=['UF'])
    max_value, min_value = gdf['Casos_entre_nascidos'].max(), gdf['Casos_entre_nascidos'].min()
    gdf['color'] = gdf['Casos_entre_nascidos'].map(lambda i: color_scale(i, max_value, min_value))

    layer = pdk.Layer(
        "GeoJsonLayer",
        gdf,
        stroked=True,
        lineWidthMinPixels=2,
        filled=True,
        get_fill_color="color",
        pickable=True,
        auto_highlight=True,
    )

    return layer

def get_hosp_hab(ano):
    gdf = gpd.read_file("./data/shapes/estados_2010.dbf")

    df = pd.read_csv("./data/cnes_hab.csv")[['sigla_uf', 'qtd', 'qtd_nasc']].groupby(by='sigla_uf').sum()
    df['uf'] = df.index

    df['qtd_hab'] = df['qtd']
    df['qtd'] = df['qtd'] / df['qtd_nasc']

    gdf = gdf.merge(df[['uf', 'qtd', 'qtd_hab']], how='left', left_on=['sigla'], right_on=['uf'])
    max_value, min_value = gdf['qtd'].max(), gdf['qtd'].min()
    gdf['color'] = gdf['qtd'].map(lambda i: color_scale_hosp(i, max_value, min_value))

    layer = pdk.Layer(
        "GeoJsonLayer",
        gdf,
        stroked=True,
        lineWidthMinPixels=2,
        filled=True,
        get_fill_color="color",
        pickable=True,
        auto_highlight=True,
    )

    return layer


def get_bar_graph(ano):
    df = pd.read_csv("./data/tabela_malformacao_%s.csv"%str(ano), index_col='UF')[['Casos_entre_nascidos','Espinha bífida','Outras malformações congênitas do sistema nervoso','Malformações congênitas do aparelho circulatório','Fenda labial e fenda palatina','Ausência atresia e estenose do intestino delgado','Outras malformações congênitas do aparelho digestivo','Testiculo não-descido','Outras malformações do aparelho geniturinário','Deformidades congênitas do quadril','Deformidades congênitas dos pés','Outras malformações e deformidades congênitas do aparelho osteomuscular','Outras malformações congênitas','Anomalias cromossômicas não classificadas em outra parte']]

    return px.bar(df, x=df.index, y=df.columns, title='Tipos de malformações congênitas pelo total de nascidos nos estados brasileiros', color_discrete_sequence=px.colors.qualitative.T10).update_layout(showlegend=False)

@callback(
    [Output('mapa_content', 'children'),
     Output('mapa_cnes_content', 'children'),
     Output('bar_content', 'figure')],
     Input('ano', 'value'),
)
def update_maps_and_chart(ano):

    # Define the map center based on shape
    lat, lon, zoom = -11.833469, -52.334267, 3

    view_state = pdk.ViewState(
        latitude=lat, longitude=lon, 
        bearing=0, pitch=0, zoom=zoom,
    )

    r1 = pdk.Deck(get_map_layer(ano), initial_view_state=view_state, map_provider='mapbox', mapbox_key=mapbox_api_token, map_style='mapbox://styles/gabriely-pereira/cl6mcphyy001214t8njwx1l55')# , api_keys={'mapbox': mapbox_api_token}))
    tooltip1 = {"html": "<b>{nome}</b> <br /><b>Casos entre nascidos:</b> {Casos_entre_nascidos}%"}

    deck_container_casos = html.Div(
        dash_deck.DeckGL(
            r1.to_json(), 
            id="deck-gl", 
            tooltip=tooltip1, 
            mapboxKey=r1.mapbox_key
        ),
        style={"height": "450px", "width": "100%", "position": "relative"},
    )

    r2 = pdk.Deck(get_hosp_hab(ano), initial_view_state=view_state, map_provider='mapbox', mapbox_key=mapbox_api_token, map_style='mapbox://styles/gabriely-pereira/cl6mcphyy001214t8njwx1l55')# , api_keys={'mapbox': mapbox_api_token}))
    tooltip2 = {"html": "<b>{uf}</b> <br /><b>Estabelecimentos com habilitação:</b> {qtd_hab} <br /><b>Proporção de estabelecimentos com habilitação:</b> {qtd}"}

    deck_container_cnes = html.Div(
        dash_deck.DeckGL(
            r2.to_json(), 
            id="deck-gl", 
            tooltip=tooltip2, 
            mapboxKey=r2.mapbox_key
        ),
        style={"height": "450px", "width": "100%", "position": "relative"},
    )
    

    return deck_container_casos, deck_container_cnes, get_bar_graph(ano)



if __name__ == '__main__':
    app.run_server(debug=True)