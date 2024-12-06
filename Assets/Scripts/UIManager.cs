using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class UIManager : MonoBehaviour
{
    public List<Canvas> menus;
    public int current_menu;
    public List<UnityEvent> onEnterMenu;


    void Awake()
    {
        Cursor.lockState = CursorLockMode.Confined;
        foreach (var m in menus)
            m.enabled = false;
        menus[current_menu].enabled = true;
        onEnterMenu[current_menu].Invoke();
    }

    public void OpenMenu(int index)
    {
        menus[current_menu].enabled = false;
        current_menu = index;
        menus[current_menu].enabled = true;
        onEnterMenu[current_menu].Invoke();
    }

    public void Quit() => Application.Quit();
}
